defmodule CF.Opengraph.Generator do
  alias DB.Schema.User
  alias DB.Schema.Video

  require EEx

  @moduledoc """
  This module gather functions to generate an xml_builder tree based on
  """

  @template_path fn ->
    # In case of a non umbrella deployment
    root = if Mix.Project.umbrella?() do
      "./apps/opengraph"
    else
      "."
    end

    Path.join(root, "lib/opengraph/template.html.eex")
  end

  EEx.function_from_file(
    :defp,
    :do_render,
    @template_path.(),
    [:description, :image, :title, :url],
    engine: Phoenix.HTML.Engine
  )

  defp render(%{
         description: description,
         image: image,
         title: title,
         url: url
       }) do
    do_render(description, image, title, url)
    |> Phoenix.HTML.safe_to_string()
  end

  # --- User ----

  @doc """
  render open graph metadata for given user
  """
  def render_user(user = %User{}, path) do
    encoded_url = URI.encode("captainfact.io#{path}")
    escaped_username = Plug.HTML.html_escape(user.username)
    escaped_appellation = Plug.HTML.html_escape(User.user_appelation(user))

    render(%{
      title: "Le profil de #{escaped_appellation} sur CaptainFact",
      url: encoded_url,
      description: "Découvrez le profil de #{escaped_username} sur CaptainFact",
      image: nil # User picture doesn't have a large enough resolution
    })
  end

  # ---- Videos ----

  @doc """
  generate open graph tags for the videos index route
  """
  def render_videos_list(path) do
    render(%{
      title: "Les vidéos sourcées et vérifiées sur CaptainFact",
      url: "captainfact.io#{path}",
      description:
        "Découvrez diverses vidéos sourcées et vérifiées par la communauté CaptainFact",
      image: nil
    })
  end

  @doc """
  generate open graph tags for the given video
  """
  def render_video(video = %Video{}, path) do
    render(%{
      title: "Vérification complète de : #{video.title}",
      url: "captainfact.io#{path}",
      description: "#{video.title} vérifiée citation par citation par la communauté CaptainFact",
      image: Video.image_url(video)
    })
  end

  # ---- Speakers ----

  @doc """
  render open graph tags for the given speaker
  """
  def render_speaker(speaker = %DB.Schema.Speaker{}, path) do
    render(%{
      title: speaker.full_name,
      description: "Les interventions de #{speaker.full_name} sur CaptainFact",
      url: "captainfact.io#{path}",
      image: nil # Speaker picture doesn't have a large enough resolution
    })
  end
end
