defmodule Charon.Fixtures do
  defmacro __using__(_opts) do
    quote do
      alias Charon.Repo.IddCodes
      alias Charon.Repo.PhoneCodes
      alias Charon.Repo.Users
      alias Charon.Repo.UserPhoneNumbers
      alias Charon.Repo.UserEmails

      @doc ~S"""
      Creates data for `idd_codes` table

      ## Returns

        [idd_code_1, idd_code_2, idd_code_3, idd_code_4]

      """
      def fixture(:idd_codes, _) do
        {:ok, q_1} = IddCodes.create(%{first_digit: 1, second_digit: 0})
        {:ok, q_2} = IddCodes.create(%{first_digit: 1, second_digit: 1})
        {:ok, q_3} = IddCodes.create(%{first_digit: 2, second_digit: 0})
        {:ok, q_4} = IddCodes.create(%{first_digit: 2, second_digit: 1})

        [q_1, q_2, q_3, q_4]
      end

      @doc ~S"""
      Creates data for `phone_codes` table

      ## Returns

        [phone_code_1, phone_code_2, phone_code_3, phone_code_4, phone_code_5, phone_code_6]

      """
      def fixture(:phone_codes, %{idd_codes: [idd_code_1, idd_code_2, idd_code_3, idd_code_4 | _]}) do
        {:ok, q_1} = PhoneCodes.create(%{idd_code_id: idd_code_1.id, code: "0"})
        {:ok, q_2} = PhoneCodes.create(%{idd_code_id: idd_code_1.id, code: "1"})
        {:ok, q_3} = PhoneCodes.create(%{idd_code_id: idd_code_2.id, code: "00"})
        {:ok, q_4} = PhoneCodes.create(%{idd_code_id: idd_code_2.id, code: "11"})
        {:ok, q_5} = PhoneCodes.create(%{idd_code_id: idd_code_3.id, code: "001"})
        {:ok, q_6} = PhoneCodes.create(%{idd_code_id: idd_code_3.id, code: "120"})
        {:ok, q_7} = PhoneCodes.create(%{idd_code_id: idd_code_4.id, code: "0001"})
        {:ok, q_8} = PhoneCodes.create(%{idd_code_id: idd_code_4.id, code: "1200"})

        [q_1, q_2, q_3, q_4, q_5, q_6, q_7, q_8]
      end

      def fixture(:users, _params) do
        attrs = %{username: nil, identity: nil, password_hash: nil, status: 10}
        0..10
        |> Enum.map(&(%{attrs | username: "Common user ##{&1 + 1}", identity: "uid_##{&1 + 1}", password_hash: "some_password_hash"}))
        |> Enum.map(
             fn x ->
               case Users.create(x) do
                 {:ok, %Users.Schema{} = q} -> q
                 _ -> raise("users fixture creation error")
               end
             end
           )
      end

      def fixture(:user_phone_numbers, %{users: users, phone_codes: phone_codes}) do
        attrs = %{user_id: nil, phone_code_id: nil, number: nil}
        0..(Enum.count(users) - 1)
        |> Enum.map(&(%{attrs | user_id: Enum.at(users, &1).id, phone_code_id: Enum.random(phone_codes).id, number: generate_string(7, '1234567890')}))
        |> Enum.map(
             fn x ->
               case UserPhoneNumbers.create(x) do
                 {:ok, %UserPhoneNumbers.Schema{} = q} -> q
                 _ -> raise("user phone number fixture creation error")
               end
             end)
      end

      def fixture(:user_emails, %{users: users}) do
        0..(Enum.count(users) - 1)
        |> Enum.map(&(%{user_id: Enum.at(users, &1).id, email: generate_string(15) <> "@example.com"}))
        |> Enum.map(
             fn x ->
               case UserEmails.create(x) do
                 {:ok, %UserEmails.Schema{} = q} -> q
                 _ -> raise("user email fixture creation error")
               end
             end)
      end

      def fixture(:user_public_keys, %{users: users}) do
        0..(Enum.count(users) - 1)
        |> Enum.map(&(%{user_id: Enum.at(users, &1).id, public_key: "some public key ##{&1}"}))
        |> Enum.map(
             fn x ->
               case UserPublicKeys.create(x) do
                 {:ok, %UserPublicKeys.Schema{} = q} -> q
                 _ -> raise("users public keys creation error")
               end
             end
           )
      end

      def fixture(:tokens, %{users: users}) do
        attrs = %{
          owner_id: nil,
          version: "1.0",
          activation_count: 1,
          identity: nil,
          description: "Some description",
          type: 1,
          confirmation_type: 1,
          required_confirmations: 3,
          activation_type: 1,
          expired_at: nil
        }
        0..(Enum.count(users) - 1)
        |> Enum.map(&(%{attrs | owner_id: Enum.at(users, &1).id, identity: "validTokenIdentity##{&1 + 1}"}))
        |> Enum.map(
             fn x ->
               case Tokens.create(x) do
                 {:ok, %Tokens.Schema{} = q} -> q
                 _ -> raise("token fixture creation error")
               end
             end)
      end

      def fixture(:token_fields, %{tokens: tokens}) do
        0..(Enum.count(tokens) - 1)
        |> Enum.reduce(
             [],
             fn i, acc ->
               id = 0..2
                    |> Enum.map(
                         fn ti ->
                           %{
                             token_id: Enum.at(tokens, i).id,
                             field: "tokenField##{i + 1}_#{ti + 1}",
                             value: "tokenFieldValue##{i + 1}_#{ti + 1}"
                           }
                         end
                       )
               acc ++ id
             end
           )
        |> Enum.map(
             fn x ->
               case TokenFields.create(x) do
                 {:ok, %TokenFields.Schema{} = q} -> q
                 _ -> raise("token fields creation error")
               end
             end
           )
      end

      def fixture(:token_shells, %{tokens: tokens, user_public_keys: user_public_keys}) do
        attrs = %{token_id: nil, user_public_key_id: nil, is_available: true, is_activated: false, dependent_sign: nil, independent_sign: nil}
        0..(Enum.count(tokens) - 1)
        |> Enum.map(&(%{
                        attrs |
                        token_id: Enum.at(tokens, &1).id,
                        user_public_key_id: Enum.at(user_public_keys, &1).id,
                        dependent_sign: "some dependent sign #{&1 + 1}",
                        independent_sign: "some independent sign #{&1 + 1}"
                      }))
        |> Enum.map(
             fn x ->
               case TokenShells.create(x) do
                 {:ok, %TokenShells.Schema{} = q} -> q
                 _ -> raise "token verifications fixture creating error"
               end
             end
           )
      end

      def fixture(:token_activation_users, %{users: users, tokens: tokens}) do
        0..(Enum.count(users) - 1)
        |> Enum.map(&(%{token_id: Enum.at(tokens, &1).id, user_id: Enum.at(users, &1).id}))
        |> Enum.map(
             fn x ->
               case TokenActivationUsers.create(x) do
                 {:ok, %TokenActivationUsers.Schema{} = q} -> q
                 _ -> raise "token activation users fixture creating error"
               end
             end
           )
      end

      def fixture(:token_confirmation_users, %{tokens: tokens, users: users}) do
        0..(Enum.count(tokens) - 1)
        |> Enum.map(&(%{token_id: Enum.at(tokens, &1).id, user_id: Enum.at(users, &1).id}))
        |> Enum.map(
             fn x ->
               case TokenConfirmationUsers.create(x) do
                 {:ok, %TokenConfirmationUsers.Schema{} = q} -> q
                 _ -> raise "token confirmation users fixture creating error"
               end
             end
           )
      end

      def fixture(:token_holders, %{tokens: tokens, users: users}) do
        0..(Enum.count(tokens) - 1)
        |> Enum.map(&(%{token_id: Enum.at(tokens, &1).id, user_id: Enum.at(users, &1).id}))
        |> Enum.map(
             fn x ->
               case TokenHolders.create(x) do
                 {:ok, %TokenHolders.Schema{} = q} -> q
                 _ -> raise "token holders fixture creating error"
               end
             end
           )
      end

      def fixture(:token_activations, %{tokens: tokens, users: users}) do
        0..(Enum.count(tokens) - 1)
        |> Enum.map(&(
          %{
            token_id: Enum.at(tokens, &1).id,
            user_id: Enum.at(users, &1).id,
            public_key: "somePublicKey##{&1 + 1}",
            sign: "someValidSign##{&1 + 1}",
            marker: generate_string(32)
          }))
        |> Enum.map(
             fn x ->
               case TokenActivations.create(x) do
                 {:ok, %TokenActivations.Schema{} = q} -> q
                 _ -> raise "token activations fixture creating error"
               end
             end
           )
      end

      def fixture(:token_confirmations, %{tokens: tokens, users: users}) do
        0..(Enum.count(tokens) - 1)
        |> Enum.map(&(
          %{
            token_id: Enum.at(tokens, &1).id,
            user_id: Enum.at(users, &1).id,
            public_key: "somePublicKey##{&1 + 1}",
            sign: "someValidSign##{&1 + 1}"
          }))
        |> Enum.map(
             fn x ->
               case TokenConfirmations.create(x) do
                 {:ok, %TokenConfirmations.Schema{} = q} -> q
                 _ -> raise "token activations fixture creating error"
               end
             end
           )
      end

      def fixture(:token_activation_notification_sheet, %{tokens: tokens, users: users}) do
        0..(Enum.count(tokens) - 1)
        |> Enum.map(&(
          %{
            user_id: Enum.at(users, &1).id,
            token_id: Enum.at(tokens, &1).id
          }))
        |> Enum.map(
             fn x ->
               case TokenActivationNotificationSheet.create(x) do
                 {:ok, %TokenActivationNotificationSheet.Schema{} = q} -> q
                 _ -> raise "token activation notification sheet fixture creating error"
               end
             end
           )
      end

      defp idd_codes(q), do: {:ok, idd_codes: fixture(:idd_codes, q)}
      defp phone_codes(q), do: {:ok, phone_codes: fixture(:phone_codes, q)}
      defp users(q), do: {:ok, users: fixture(:users, q)}
      defp user_public_keys(q), do: {:ok, user_public_keys: fixture(:user_public_keys, q)}
      defp user_phone_numbers(q), do: {:ok, user_phone_numbers: fixture(:user_phone_numbers, q)}
      defp user_emails(q), do: {:ok, user_emails: fixture(:user_emails, q)}
      defp tokens(q), do: {:ok, tokens: fixture(:tokens, q)}
      defp token_shells(q), do: {:ok, token_shells: fixture(:token_shells, q)}
      defp token_fields(q), do: {:ok, token_fields: fixture(:token_fields, q)}
      defp token_activation_users(q), do: {:ok, token_activation_users: fixture(:token_activation_users, q)}
      defp token_confirmation_users(q), do: {:ok, token_confirmation_users: fixture(:token_confirmation_users, q)}
      defp token_holders(q), do: {:ok, token_holders: fixture(:token_holders, q)}
      defp token_activations(q), do: {:ok, token_activations: fixture(:token_activations, q)}
      defp token_confirmations(q), do: {:ok, token_confirmations: fixture(:token_confirmations, q)}
      defp token_activation_notification_sheet(q),
           do: {:ok, token_activation_notification_sheet: fixture(:token_activation_notification_sheet, q)}

      setup [
        :idd_codes,
        :phone_codes,
        :users,
        :user_public_keys,
        :user_phone_numbers,
        :user_emails,
        :tokens,
        :token_fields,
        :token_activation_users,
        :token_confirmation_users,
        :token_holders,
        :token_activations,
        :token_confirmations,
        :token_activation_notification_sheet,
        :token_shells
      ]
    end
  end
end
