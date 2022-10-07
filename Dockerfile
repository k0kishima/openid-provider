FROM ruby:3.0.2

WORKDIR /webapp

ENTRYPOINT [ "./entrypoint.sh" ]

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]

