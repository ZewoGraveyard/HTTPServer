has_source_changes = !modified_files.grep(/Sources/).empty?
has_test_changes = !modified_files.grep(/Tests/).empty?
trivial_changes = pr_title.include? "#trivial" || !has_source_changes
github = env.request_source.client
organization, repository = env.ci_source.repo_slug.split("/")

unless github.organization_member?(organization, pr_author)
    message "Hey @#{pr_author}, you're not a member of #{organization} yet. Would you like to join the #{organization} Github organization?\nYou can also join our [Slack](http://slack.zewo.io) and interact with a great community of developers. 😊"
end

if modified_files.include? "Package.swift"
    warn "Package.swift was updated"
end

if pr_title.include? "[WIP]"
    warn "PR is classed as Work in Progress"
end

if lines_of_code > 500
    warn "Big PR"
end

if has_source_changes && !has_test_changes
  warn "Tests were not updated"
end

if pr_body.length < 5
  fail "Please provide a summary in the Pull Request description"
end

if !trivial_changes && !modified_files.include?("CHANGELOG.md")
  fail "Please include a CHANGELOG entry. \nYou can find it at CHANGELOG.md"
end

(modified_files + added_files).select { |f| File.read(f) =~ /all rights reserved/i }.each {|f| fail("#{f} includes all rights reserved" }
