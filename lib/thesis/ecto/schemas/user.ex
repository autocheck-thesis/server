defmodule Thesis.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field(:lti_user_id, :string)
    has_many(:submissions, {"author_id", Thesis.Submission})

    timestamps()
  end

  @required_fields [:lti_user_id]

  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
  end

  def find_or_create(lti_user_id) do
    case Thesis.Repo.one(from(user in Thesis.User, where: user.lti_user_id == ^lti_user_id)) do
      nil ->
        user =
          Thesis.User.changeset(%Thesis.User{}, %{"lti_user_id" => lti_user_id})
          |> Thesis.Repo.insert!()

        Logger.debug("Creating user at launch: #{inspect(user)}")

        user

      user ->
        Logger.debug("Found existing user at launch: #{inspect(user)}")
        user
    end
  end
end
