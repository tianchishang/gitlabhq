require 'spec_helper'

feature 'Master deletes tag', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.team << [user, :master]
    login_with(user)
    visit namespace_project_tags_path(project.namespace, project)
  end

  context 'from the tags list page', js: true do
    scenario 'deletes the tag' do
      expect(page).to have_content 'v1.1.0'

      delete_first_tag

      expect(page).not_to have_content 'v1.1.0'
    end
  end

  context 'from a specific tag page' do
    scenario 'deletes the tag' do
      click_on 'v1.0.0'
      expect(current_path).to eq(
        namespace_project_tag_path(project.namespace, project, 'v1.0.0'))

      click_on 'Delete tag'

      expect(current_path).to eq(
        namespace_project_tags_path(project.namespace, project))
      expect(page).not_to have_content 'v1.0.0'
    end
  end

  context 'when pre-receive hook fails', js: true do
    before do
      allow_any_instance_of(GitHooksService).to receive(:execute)
        .and_raise(GitHooksService::PreReceiveError, 'Do not delete tags')
    end

    scenario 'shows the error message' do
      delete_first_tag

      expect(page).to have_content('Do not delete tags')
    end
  end

  def delete_first_tag
    page.within('.content') do
      first('.btn-remove').click
    end
  end
end
