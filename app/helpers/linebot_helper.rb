module LinebotHelper
  def save_memo(input)
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
  end
end
