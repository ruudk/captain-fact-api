defmodule DB.Schema.Video do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias DB.Schema.{Speaker, Statement, VideoSpeaker}

  @providers_urls %{
    # Map a provider name to its regex, using named_captures to get the id --------------------↘️
    "youtube" => ~r/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)(?<id>[^"&?\/ ]{11})/i
  }

  # Define schema

  schema "videos" do
    field :title, :string
    field :url, :string, virtual: true
    field :provider, :string, null: false
    field :provider_id, :string, null: false
    field :language, :string, null: true
    field :unlisted, :boolean, null: false

    many_to_many :speakers, Speaker, join_through: VideoSpeaker, on_delete: :delete_all
    has_many :statements, Statement, on_delete: :delete_all

    timestamps()
  end

  # Define queries

  def query_list(query, filters \\ []) do
    query
    |> where([v], v.unlisted == false)
    |> order_by([v], desc: v.id)
    |> filter_with(filters)
  end

  def with_speakers(query) do
    from v in query, preload: [:speakers]
  end

  def with_statements(query) do
    from v in query, preload: [:statements]
  end

  defp filter_with(query, filters) do
    Enum.reduce(filters, query, fn
      {:language, "unknown"}, query ->
        from v in query, where: is_nil(v.language)
      {:language, language}, query ->
        from v in query, where: v.language == ^language
      {:speaker_id, id}, query ->
        from v in query, join: s in assoc(v, :speakers), where: s.id == ^id
      {:speaker_slug, slug}, query ->
        from v in query, join: s in assoc(v, :speakers), where: s.slug == ^slug
      {:min_id, id}, query ->
        from v in query, where: v.id > ^id
    end)
  end

  # Utils

  def is_valid_url(url) do
    Enum.find_value(@providers_urls, false, fn {_, regex} -> Regex.match?(regex, url) end)
  end

  def build_url(%{provider: "youtube", provider_id: id}) do
    "https://www.youtube.com/watch?v=#{id}"
  end

  # Changesets

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title, :language])
    |> validate_required([:url, :title])
    |> parse_url()
    |> validate_required([:provider, :provider_id])
    |> validate_length(:title, min: 5, max: 120)
    |> unique_constraint(:videos_provider_provider_id_index)
    |> update_change(:language, &(hd(String.split(&1, "-")))) # Change "en-US" to "en"
  end

  def parse_url(changeset = %Ecto.Changeset{}) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{url: url}} ->
        case parse_url(url) do
          {provider, id} ->
            changeset
            |> put_change(:provider, provider)
            |> put_change(:provider_id, id)
          _ ->
            add_error(changeset, :url, "invalid_url")
        end
      _ ->
        changeset
    end
  end
  def parse_url(url) when is_binary(url) do
    Enum.find_value(@providers_urls, fn {provider, regex} ->
      case Regex.named_captures(regex, url) do
        %{"id" => id} -> {provider, id}
        nil -> nil
      end
    end)
  end
end
