# Container image for self-hosting texbrain. Additive to upstream — nothing under
# src/ is touched, so `git merge upstream/main` stays conflict-free.
#
# The build stage mirrors .github/workflows/deploy.yml (node 20, pnpm 9) so the
# image is produced by the same toolchain that produces the GitHub Pages site.

FROM node:20-alpine AS build
WORKDIR /src

RUN corepack enable && corepack prepare pnpm@9 --activate

# Manifest first: a source-only change then reuses the install layer.
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm build

# nginx-unprivileged rather than nginx: it listens on 8080 and runs as uid 101,
# so the image needs no root and works under readOnlyRootFilesystem with only
# /var/cache/nginx and /etc/nginx/tmp mounted writable.
FROM nginxinc/nginx-unprivileged:alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/build /usr/share/nginx/html

EXPOSE 8080
