defmodule BeaconWeb.Layouts do
  use BeaconWeb, :html
  require Logger

  embed_templates "layouts/*"

  def render_dynamic_layout(%{__dynamic_layout_id__: layout_id, beacon_site: site} = assigns) do
    module = Beacon.Loader.layout_module_for_site(site)
    Beacon.Loader.call_function_with_retry(module, :render, [layout_id, assigns])
  end

  def page_title(%{layout_assigns: %{page_title: page_title}}), do: page_title

  def page_title(%{__dynamic_layout_id__: layout_id, beacon_site: site}) do
    %{title: title} = compiled_layout_assigns(site, layout_id)
    title
  end

  def page_title(_) do
    Logger.warn("No page title set")
    ""
  end

  # for dynamic pages
  def meta_tags(%{__dynamic_layout_id__: _, beacon_site: _} = assigns) do
    {:safe, meta_tags_unsafe(assigns)}
  end

  def meta_tags(_), do: ""

  def meta_tags_unsafe(assigns) do
    assigns
    |> get_meta_tags()
    |> Enum.map_join("\n", fn {key, value} ->
      # TODO: escape key/values here
      "    <meta property=\"#{key}\" content=\"#{value}\">"
    end)
  end

  # for non dynamic pages

  def get_meta_tags(%{layout_assigns: %{meta_tags: meta_tags}} = assigns) do
    assigns
    |> compiled_meta_tags()
    |> Map.merge(meta_tags)
  end

  def get_meta_tags(assigns) do
    compiled_meta_tags(assigns)
  end

  def dynamic_layout?(%{__dynamic_layout_id__: _}), do: true
  def dynamic_layout?(_), do: false

  defp compiled_meta_tags(%{__dynamic_layout_id__: layout_id, beacon_site: site}) do
    %{meta_tags: compiled_meta_tags} = compiled_layout_assigns(site, layout_id)
    compiled_meta_tags
  end

  defp compiled_layout_assigns(site, layout_id) do
    module = Beacon.Loader.layout_module_for_site(site)

    Beacon.Loader.call_function_with_retry(module, :layout_assigns, [layout_id])
  end

  def stylesheet_tag(%{__dynamic_layout_id__: _, beacon_site: site}) do
    module = Beacon.Loader.stylesheet_module_for_site(site)

    stylesheet_tag = Beacon.Loader.call_function_with_retry(module, :render, [])
    {:safe, stylesheet_tag}
  end

  def stylesheet_tag(_), do: ""

  def linked_stylesheets(%{__dynamic_layout_id__: _, beacon_site: _} = assigns) do
    {:safe, linked_stylesheets_unsafe(assigns)}
  end

  def linked_stylesheets(_), do: ""

  def linked_stylesheets_unsafe(assigns) do
    assigns
    |> get_linked_stylesheets()
    |> Enum.map_join("\n", fn sheet ->
      # TODO: escape key/values here
      ~s(    <link rel="stylesheet" href="#{sheet}">)
    end)
  end

  # for non dynamic pages

  def get_linked_stylesheets(%{layout_assigns: %{linked_stylesheets: linked_stylesheets}} = assigns) do
    assigns
    |> compiled_linked_stylesheets()
    |> Map.merge(linked_stylesheets)
  end

  def get_linked_stylesheets(assigns) do
    compiled_linked_stylesheets(assigns)
  end

  defp compiled_linked_stylesheets(%{__dynamic_layout_id__: layout_id, beacon_site: site}) do
    %{stylesheet_urls: compiled_linked_stylesheets} = compiled_layout_assigns(site, layout_id)
    compiled_linked_stylesheets
  end
end
