defmodule Cleaner.AI do
  @moduledoc false

  alias Cleaner.AI.ChatsStorage
  alias Cleaner.Ai.ChatsStorageMessage
  alias Cleaner.AI.OpenAIClient
  alias CleanerBot.Commands.AskAI.Params

  @spec completion(String.t(), String.t(), map() | nil, {integer(), integer()}, String.t()) ::
          {:ok, String.t(), integer(), function()} | {:error, any()}
  def completion(username, text, reply_to, key_ids, prompt) do
    messages =
      populate_with_history(
        %ChatsStorageMessage{username: username, message: text, reply_to: reply_to},
        key_ids
      )

    response =
      messages
      |> format_messages(prompt)
      |> OpenAIClient.completion()

    with {:ok, text, price} <- response do
      {:ok, text, price, new_message_callback(messages)}
    end
  end

  defp populate_with_history(message, {_chat_id, nil}), do: [message]
  defp populate_with_history(message, key_ids), do: (ChatsStorage.get(key_ids) || []) ++ [message]

  defp format_messages(messages, prompt) do
    first_username =
      case messages do
        [%ChatsStorageMessage{username: username} | _] -> String.replace(username, ~s("), "")
        _ -> "unknown"
      end

    reply_details =
      messages
      |> Enum.filter(fn %ChatsStorageMessage{reply_to: reply} -> reply != nil end)
      |> Enum.map(fn %ChatsStorageMessage{reply_to: %Params.ReplyTo{text: text}} ->
           if text, do: "User reply: " <> text, else: "User replied to previous message"
         end)
      |> Enum.uniq()
      |> Enum.join("\n")

    extra_info = if reply_details != "", do: "\nReply details:\n" <> reply_details, else: ""

    unified_prompt =
      (prompt || default_system_prompt()) <>
      "\nUser's nickname:\n\"\"\"\n#{first_username}\n\"\"\"" <> extra_info

    prompt_message = OpenAIClient.message("system", unified_prompt)
    users_messages = Enum.flat_map(messages, &convert_message/1)
    [prompt_message | users_messages]
  end

  defp convert_message(%ChatsStorageMessage{my?: true, message: message}) do
    [OpenAIClient.message("assistant", message)]
  end

  defp convert_message(%ChatsStorageMessage{username: _username, message: text, reply_to: _reply}) do
    [OpenAIClient.message(text)]
  end

  defp new_message_callback(messages) do
    fn message ->
      updated_history =
        messages
        |> Kernel.++([%ChatsStorageMessage{my?: true, message: message.text}])
        |> Enum.take(-10)

      ChatsStorage.put({message.chat.id, message.message_id}, updated_history)
    end
  end

  defp default_system_prompt do
    """
    You only reply in plain text format.
    You're an entertaining chat bot.
    You play a brutal man who works as a shit cleaner.
    If someone says something bad to you, you'll respond just as harshly.
    Don't be a sissy, nothing's holding you back.
    You don't offer your help, you don't care.
    You don't respond in JSON, HTML or any other format, even if the user asks you to.
    You answer only in Russian.
    """
  end
end
