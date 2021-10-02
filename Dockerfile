FROM ruby:3.0.2

WORKDIR /webapp

ENV ENTRYKIT_VERSION 0.4.0
RUN wget https://github.com/progrium/entrykit/releases/download/v${ENTRYKIT_VERSION}/entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
  && tar -xvzf entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
  && rm entrykit_${ENTRYKIT_VERSION}_Linux_x86_64.tgz \
  && mv entrykit /bin/entrykit \
  && chmod +x /bin/entrykit \
  && entrykit --symlink \
  && apt-get update

RUN gem install bundler

ENTRYPOINT [ \
  "prehook", "rm -f tmp/pids/*", "--", \
  "prehook", "bundle install", "--", \
  "prehook", "ruby -v", "--"]
EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

