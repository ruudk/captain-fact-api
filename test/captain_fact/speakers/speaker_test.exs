defmodule CaptainFact.Speakers.SpeakerTest do
  use CaptainFact.DataCase, async: true

  alias CaptainFact.Speakers.Speaker

  @valid_attrs %{
    full_name: "#{Faker.Name.first_name} #{Faker.Name.last_name}"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Speaker.changeset(%Speaker{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Speaker.changeset(%Speaker{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "full name must be between 3 and 60 characters" do
    # Too short
    attrs = %{full_name: "x"}
    assert {:full_name, "should be at least 3 character(s)"} in errors_on(%Speaker{}, attrs)

    # Too long
    attrs = %{full_name: String.duplicate("x", 61)}
    assert {:full_name, "should be at most 60 character(s)"} in errors_on(%Speaker{}, attrs)
  end

  test "title must be between 3 and 60 characters" do
    # Too short
    attrs = %{title: "x"}
    assert {:title, "should be at least 3 character(s)"} in errors_on(%Speaker{}, attrs)

    # Too long
    attrs = %{title: String.duplicate("x", 61)}
    assert {:title, "should be at most 60 character(s)"} in errors_on(%Speaker{}, attrs)
  end

  test "name and title are trimmed" do
    changeset = Speaker.changeset(%Speaker{}, Map.put(@valid_attrs, :full_name, "   Hector    "))
    assert changeset.changes.full_name == "Hector"

    changeset = Speaker.changeset(%Speaker{}, Map.put(@valid_attrs, :title, "   King     of the world    "))
    assert changeset.changes.title == "King of the world"
  end
end
