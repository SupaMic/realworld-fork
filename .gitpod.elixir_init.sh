#!/bin/bash

# These should be done in order and before mix deps.get and mix compile

# Verify postgres database credentials because if docker image starts `FROM gitpod/workspace-postgres`, 
# then it seems to use `gitpod` as the default owner on the postgres DB setup

# Check if the user exists
user_exists=$(psql -U gitpod -c "SELECT usename FROM pg_user WHERE usename='postgres';" -t)

if [[ -z "$user_exists" ]]; then
  echo "Creating postgres user to be compatible with default Elixir dev config..."
  
  # Create the user
  psql -U gitpod -c "CREATE USER postgres SUPERUSER;ALTER USER postgres PASSWORD 'postgres';"
  psql -U gitpod -c "ALTER DATABASE postgres OWNER TO postgres;"
  psql -U gitpod -c "GRANT ALL PRIVILEGES ON DATABASE postgres TO gitpod;"
  echo "'postgres' user created successfully and made owner of 'postgres' db!"
else
  echo "'postgres' user already exists."
fi;



# force the install (--if-missing arg is >= Elixir v1.13)
mix local.hex --force --if-missing
mix local.rebar --force --if-missing
# mix local.hex --force
# mix local.rebar

# check if HEX installed via asdf, and if not install
# Run mix hex.info to see if exists, $MIX_HOME is set in .gitpod.ElixirDockerfile

echo "Checking Hex version in $MIX_HOME...";

if echo $(mix hex) | grep -q "Hex v2."; then
  echo "Hex package manager is already installed."
else
  echo "Hex package manager is not installed. Installing...";
  mix local.hex --force;

  if [ $? -eq 0 ]; then
    echo "Hex package manager installed successfully."
  else
    echo "Failed to install Hex package manager."
  fi;
fi;

# Determine is if Rebar3 was installed properly using asdf
mix_path=$(asdf which mix)
mix_directory=$(dirname "$mix_path")
mix_directory=${mix_directory%/bin}  # Remove '/bin' from the end of the path

#Parsing to dermine the path of asdf install dir
elixir_version=$(elixir --version | grep -oE "Elixir [0-9]+\.[0-9]+\.[0-9]+" | awk '{print $2}')
major_version=$(echo "$elixir_version" | cut -d "." -f 1)
minor_version=$(echo "$elixir_version" | cut -d "." -f 2)
internal_mix_path="$mix_directory/.mix/elixir/$major_version-$minor_version"

rebar_bin_path="$internal_mix_path/rebar3"
rebar_info=$($rebar_bin_path -v)

if echo "$rebar_info" | grep -q "rebar 3."; then
  echo "Rebar3 package manager is already installed."
else
  echo "Rebar3 package manager is not installed. Installing..."
  mix local.rebar --force

  if [ $? -eq 0 ]; then
    echo "Rebar3 package manager installed successfully."
  else
    echo "Failed to install Rebar3 package manager."
  fi
fi
# --if-needed argument makes these install checks redundant however, dynamically determining the 
# Elixir version asdf path routes might be useful for other deployment scenarios like umbrellas

# This adds support for elixir-lsp.elixir-ls and victorbjorklund.phoenix extensions 
# (in theory, but in practice the extensions themselves are somewhat unreliable in vscode-remote IDE)
# so in short, this configuration and extension setup *needs work*
json_file="/workspace/.vscode-remote/data/Machine/settings.json"
# Read the JSON file and add the new key-value pair
updated_json=$(jq '. + { "emmet.includeLanguages": { "phoenix-heex": "html", "html-eex": "html" } }' "$json_file")
# Write the updated JSON back to the file
echo "$updated_json" > "$json_file"