[![](https://images.microbadger.com/badges/image/rawmind/alpine-ruby.svg)](https://microbadger.com/images/rawmind/alpine-ruby "Get your own image badge on microbadger.com")

alpine-ruby
==============

This image is ruby base. It comes from [alpine-monit][alpine-monit].

## Build

```
docker build -t rawmind/alpine-ruby:<version> .
```

## Versions

- `2.5.1-1` [(Dockerfile)](https://github.com/rawmind0/alpine-ruby/blob/2.5.1-1/Dockerfile)

## Usage

To use this image include `FROM rawmind/alpine-ruby` at the top of your `Dockerfile`. Starting from `rawmind/alpine-monit` provides you with the ability to easily start any service using monit. monit will also keep it running for you, restarting it when it crashes.

To start your service using monit:

- create a monit conf file in `/opt/monit/etc/conf.d`
- create a service script that allow start, stop and restart function


[alpine-monit]: https://github.com/rawmind0/alpine-monit/

