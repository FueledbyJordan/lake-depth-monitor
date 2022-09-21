# Lake Depth Monitor

Lake Depth Monitor is an application that alerts a user via email about a lake's pool depth.  Upon a successful run, it pings an endpoint for administrative monitoring.

I'm being intentionally vague about the endpoint that container monitors to respect the data provider.  They do not have a documented public facing API, so I had to reverse engineer the appropriate endpoints.

## Installation

Use the docker container.

```bash
docker pull fueledbyjordan/lake-depth-monitor:latest
```

## Usage

It is recommended to use docker.compose to manage the container lifecycle.  An example is provided in the project's [docker-compose.yml file](./docker-compose.yml).

* I use [healthchecks.io](healthchecks.io) for my administrative monitoring.
* I use [sendgrid](sendgrid.com) as a smtp relay.

## Acknowledgements

* [Supercronic](https://github.com/aptible/supercronic)

## Contact

Want to get a hold of me?  I can be reached at [djm@murrayfoundry.com](mailto:djm@murrayfoundry.com).

## License
[MIT](https://choosealicense.com/licenses/mit/)
