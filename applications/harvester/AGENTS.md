# Harvester

This OpenTofu stack runs on a Harvester/K3s cluster.

## Adding a new service

Refer to existing examples for services when adding a new one. Reuse the modules that are made available in the `../modules-harvester` directory.

When configuring a new service, remember the following:

 * When setting up the ports, the `container` port is whatever port the application listens on. This is usually found in its documentation. The `service` port should, in almost all cases, be `80`, as this is what the service module is configured to connect to.
