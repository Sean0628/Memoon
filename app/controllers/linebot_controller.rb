class LinebotController < ApplicationController
  require 'line/bot' # line-bot-api

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery except: :callback

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token  = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each { |event|
      line_id = params['events'][0]['source']['userId']
      # generate new user, or find the user if it has already existed.
      @user = User.find_or_create_by!(line_id: line_id)
      case event
      # delete action
      when Line::Bot::Event::Postback
        # take the action and the memo id from parameters
        action = params['events'][0]['postback']['data'].split('&')[0]
        memo_id = params['events'][0]['postback']['data'].split('&')[1]
        if action == "delete"
          @memo = Memo.find(memo_id)
          # if successfully deleted
          if memo_owner?(@memo, @user)
            if @memo.destroy!
              message = {
                "type": "text",
                "text": "メモを削除しました！"
              }
            # cannot delete memo
            else
              message = {
                "type": "text",
                "text": "エラーが発生しました。"
              }
            end
            client.reply_message(event['replyToken'], message)
          end
        end
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          input = event.message['text']
          # display 10 new memos
          case input
          when 'List', 'list', 'LIST', 'リスト', 'りすと'
            @memos = @user.memos.order('created_at DESC').limit(10)
            client.reply_message(event['replyToken'], generate_carousel(@memos))
          # display all memos in descending order
          when 'All', 'all', 'ALL', '一覧', '全て', 'すべて'
            @memos = @user.memos.order('created_at DESC')
            client.reply_message(event['replyToken'], generate_list(@memos))
          # generate new memos
          else
            # if it includes a title.
            if has_title?(input)
              # gets the title.
              title = input.split("\n")[0]
              # gets the body.
              body = input.split("\n").drop(1).join("\n")
            # if there is not a title
            else
              title = "##{input[0..10]}"
              body = input
            end
            @user.memos.create!(title: title, body: body)
            message = {
              "type": "text",
              "text": "新しくメモを作りました！"
            }
            client.reply_message(event['replyToken'], message)
          end
        end
      end
    }
  end

  private
  def has_title?(input)
    input.start_with?('#' || '＃')
  end

  def memo_owner?(memo, user)
    memo.user.line_id == user.line_id
  end

  # generate massege lists
  def generate_carousel(memos)
    unless memos.empty?
      columns = []
        memos.each do |memo|
          columns << generate_column(memo)
        end
      message = {
        "type": "template",
        "altText": "メモのリスト",
        "template": {
          "type": "carousel",
          "columns": columns
        }
      }
    else
      message = {
        "type": "text",
        "text": "現在メモはありません。"
      }
    end
    message
  end

  # generate column lists
  def generate_column(memo)
    column = {
      "imageBackgroundColor": "#FFFFFF",
      "title": "#{memo.title}",
      "text": "#{memo.body}",
      "actions": [
        {
          "type": "postback",
          "label": "削除",
          "data": "delete&#{memo.id}",
        }
      ]
    }
    column
  end

  # generate lists with all memo's title
  def generate_list(memos)
    partition = "---------------------------------"
    text = ""
    memos.each do |memo|
      text << "#{memo.title}\n"
    end
    text << "\n#{partition}
              表示したいメモのタイトルをメッセージとして送信してください。
              \n#{partition}"
    lists = {
      "type": "text",
      "text": text
    }
    lists
  end
end
