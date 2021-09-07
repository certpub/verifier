FROM ruby:2.7.4

ADD . /work

WORKDIR /work

RUN bundle

USER 1000

CMD ["--help"]
ENTRYPOINT ["ruby", "/work/src/main.rb"]
