# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example

has_source_changes = !modified_files.grep(/Sources/).empty?
has_test_changes = !modified_files.grep(/Tests/).empty?
declared_trivial = pr_title.include? "#trivial" || !has_source_changes
octo_client = env.request_source.client

# Make a note about contributors not in the organization
unless octo_client.organization_member?('VeniceX', pr_author)
  message "@#{pr_author} is not a contributor yet, would you like to join VeniceX?"

#  if modified_files.include?("*.gemspec")
#    warn "External contributor has edited the Gemspec"
#  end
end

if pr_body.length < 5
  fail "Please provide a summary in the Pull Request description"
end

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("Big PR") if lines_of_code > 500

if has_source_changes && !has_test_changes
  warn "Tests were not updated"
end

if !modified_files.include?("CHANGELOG.md") && !declared_trivial
  fail("Please include a CHANGELOG entry. \nYou can find it at CHANGELOG.md")
end
