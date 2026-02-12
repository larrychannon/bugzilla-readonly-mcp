#!BuildTag: bugzilla-readonly-mcp:%VERSION%
#!UseOBSRepositories

FROM registry.opensuse.org/opensuse/bci/python:3.13
COPY . /app
WORKDIR /app
RUN zypper --non-interactive in python313-uv && uv sync --locked
ENTRYPOINT ["uv", "run", "bugzilla-readonly-mcp"]
