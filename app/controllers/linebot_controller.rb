class LinebotController < ApplicationController
  require 'line/bot' # line-bot-api'

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
      user_id = event.source['userId']
      # generate new user, or find the user if it has already existed.
      user = User.find_or_create_by!(user_id: user_id)
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          input = event.message['text']
          # if it includes a title.
          if input.start_with?('#' || '＃')
            # gets the title.
            title = input.split("\n")[0]
            # gets body.
            body = input.split("\n").drop(1).join("\n")
          # if there is not a title
          else
            title = "##{input[0..10]}"
            body = input
          end
          user.memos.create!(title: title, body: body)
          message = {
            type: 'text',
            text: '新しくメモを作りました！'
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    }
  end
end
