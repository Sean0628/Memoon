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
      # delete or edit action
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
          # display all memos
          case input
          when 'List', 'list', 'LIST', 'リスト', 'りすと'
            @memos = @user.memos.limit(10)
            client.reply_message(event['replyToken'], generate_message(@memos))
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
  def generate_message(memos)
    message = {
      "type": "template",
      "altText": "メモの一覧リスト",
      "template": {
        "type": "carousel",
        "columns": [
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[0].title}",
            "text": "#{memos[0].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit#{memos[0].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[0].id}",
              }
            ]
          },
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[1].title}",
            "text": "#{memos[1].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit&#{memos[1].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[1].id}",
              }
            ]
          },
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[2].title}",
            "text": "#{memos[2].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit&#{memos[2].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[2].id}",
              }
            ]
          },
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[3].title}",
            "text": "#{memos[3].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit&#{memos[3].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[3].id}",
              }
            ]
          },
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[4].title}",
            "text": "#{memos[4].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit&#{memos[4].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[4].id}",
              }
            ]
          },
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[5].title}",
            "text": "#{memos[5].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit&#{memos[5].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[5].id}",
              }
            ]
          },
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[6].title}",
            "text": "#{memos[6].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit&#{memos[6].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[6].id}",
              }
            ]
          },
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[7].title}",
            "text": "#{memos[7].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit&#{memos[7].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[7].id}",
              }
            ]
          },
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[8].title}",
            "text": "#{memos[8].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit&#{memos[8].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[8].id}",
              }
            ]
          },
          {
            "imageBackgroundColor": "#FFFFFF",
            "title": "#{memos[9].title}",
            "text": "#{memos[9].body}",
            "actions": [
#              {
#                "type": "postback",
#                "label": "編集",
#                "data": "edit&#{memos[9].id}",
#              },
              {
                "type": "postback",
                "label": "削除",
                "data": "delete&#{memos[9].id}",
              }
            ]
          },
        ]
      }
    }
    message
  end
end
