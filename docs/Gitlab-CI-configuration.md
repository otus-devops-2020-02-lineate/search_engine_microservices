# Gitlab CI configuration

- Go to http://gitlab-gitlab/dashboard/groups
- Create group for your project (group name should match group name in Docker Hub)
- Go to http://gitlab-gitlab/{groupPath} and add three projects:
  - `search-engine-infra` - for infrastructure and deployment code
  - `search-engine-crawler` - for crawler backend
  - `search-engine-ui` - for search UI
- Add new remotes to your repositories, like `git remote add gitlab git@gitlab-gitlab:{groupPath}/search-engine-ui.git`
- Push your code into repositories `git push gitlab master`
