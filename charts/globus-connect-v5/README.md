# Globus Connect Server v5

*Image source*: https://github.com/slateci/container-gcs5

## Installation

This SLATE application requires the creation of two secrets in order to be
used. Before deploying this chart, you will need to create a passwd(5)-like
user list with encrypted passwords, and you will additionally need to generate 
credentials for the endpoint on the globus.org website and using the 
`globus-connect-server` cli command.

### Creating the endpoint credentials

The following must be created *before* instantiating a GCSv5 container so
that the endpoint will be configured correctly.

* Login on globus.org and go to the Settings>Developers page
* If you have an already created project for the globus connect server, select it
* Otherwise create a new project by doing the following:
   * Click on the `Advanced Registration` option
   * Select `the none of the above - create a new project` option and press `Continue`
   * Fill in the information on the new project and press Continue
   * Select a globus id (i.e. your username when logging into globus.org) and sign in if requested to
   * Once you get to the App Registration page, click Cancel
   * You'll be be back at the Developers page and should see the new project on the column on the right, select it
* Add an app and under the type, select 'Register a Globus Connect Server'
* Create a new registration with the appropriate fields 
* Make sure to record the client uuid since this will be needed
* Create a new client secret and record the secret (this is the only time it will be displayed)
* Either:
  * Install [globus connect 5.4](https://docs.globus.org/globus-connect-server/v5/quickstart/#gcsv5-install) on a system 
  * Or run `docker run  -it  --rm hub.opensciencegrid.org/slate/globus-connect-v5-setup:0.1  ` to get a container with 
    globus connect 5.4 installed
* Use the container or the system to run

  ```shell
  $ globus-connect-server endpoint setup [endpoint_name] \
        --contact-email [email] -o [globus_id] --organization [org] \
        -c [client_uuid]
  ``` 

  replacing `[endpoint_name]` with your endpoint's name (you can make one up), `[email]` with your contact email, 
  `[globus_id]` with your globus login id (e.g. `sthapa@globusid.org`), `[org]` with your organization, and
  `[client_uuid]` with the client uuid you got from the globus.org website.
* The setup procedure may take a while to complete due to some of the steps involved.  
* The setup will request the secret that you generated and then create a `deployment-key.json` file that you *must* keep


Create a new file with the contents:

```
GLOBUS_CLIENT_ID=<client_uuid>
GLOBUS_CLIENT_SECRET=<secret>
DEPLOYMENT_KEY=<contents of deployment-key.json>
```

Make sure that the file that you have created does not have any empty files,
otherwise SLATE will give an error when creating a secret using this file.

And then create the credential with:


```shell
$ slate secret create <secret-name> --group <group> --cluster <cluster> \
    --from-env-file <filename>
```


### Generating the passwd(5) file 

The user entries in this file will be added to the container.  The Globus endpoint
will map incoming users to the users in the passwd file in order
to access and write files.   I.e. this file will be used to create users
that globus connect can use when doing transfers.


This chart will consume a file in the format of /etc/passwd. This
hash will be stored as a SLATE secret (re-encrypted in DynamoDB). 


You will need to provide an extended passwd(5)-format file with a dummy
placeholder in the second field (e.g. `x`):

```
   slateci:x:1001:1001:SLATE CI:/home/slateci:/bin/bash
```

You can then copy users out of /etc/passwd or create them by hand. From the
passwd(5) manual:

```
Each line of the file describes  a  single  user,  and  contains  seven
colon-separated fields:

       name:password:UID:GID:GECOS:directory:shell

The field are as follows:

name        This is the user's login name.  It should not contain capi‐
            tal letters.

password    This is should be the letter 'x'.  (See pwconv(8) for an explanation
            of 'x'.)

UID         The privileged root login account (superuser) has the  user
            ID 0.

GID         This is the numeric primary group ID for this user.  (Addi‐
            tional groups for the user are defined in the system  group
            file; see group(5)).

GECOS       This  field  (sometimes  called  the  "comment  field")  is
            optional and used only for  informational  purposes.   Usu‐
            ally,  it  contains  the full username.  Some programs (for
            example, finger(1)) display information from this field.

directory   This is the user's home directory:  the  initial  directory
            where  the  user  is placed after logging in.  The value in
            this field is used to set the HOME environment variable.

shell       This is  the  program  to  run  at  login  (if  empty,  use
            /bin/sh).   If  set  to  a nonexistent executable, the user
            will be unable to login through  login(1).   The  value  in
            this field is used to set the SHELL environment variable.
```

Note that only name, password, UID, and directory are respected in the current
release.

Once you have a passwd file setup, you can create a secret using:

```shell
$ slate secret create <secret-name> --group <group> --cluster <cluster> \
    --from-file passwd
```


### Deploying 
To deploy the chart, first get the values file and store it:

```
slate app get-conf --dev globus-connect-v5 > gcs.yaml
```

Edit to your liking (notably the GlobusCredentialSecret and GlobusPasswdSecret must match what you have created in previous steps) and deploy with:

```
slate app install --cluster <cluster> --group <group> --dev globus-connect-v5 --conf gcs.yaml
```

This will return an instance ID, please note this as it will be needed later.

---
# Configuration and Usage

## Backing Storage

This application can use just the ephemeral storage of it own container, an
external filesystem provided by the host system, or a PersistentVolumeClaim as
the backing storage to (or from) which it can transfer data. If neither
`InternalPath` nor `PVCName` is set, only ephemeral storage will be available.
`InternalPath` can be set to refer to a path on the host system which should be
mounted, or `PVCName` name can be set to mount a PVC by name. If either option
is used to mount a volume, `ExternalPath` can be used to set the path within
the container at which it will be mounted. 

## Configuring a Globus endpoint 

### Manual Configuration

Once the endpoint has been deployed, you can look at the logs to get the endpoint 
id.  It should be an uuid that's similar to `66b11297-368a-41cb-bbe4-67b3772cf85f`.

In order to configure the endpoint:

* View the logs for the deployed endpoint and get the endpoint id that is printed out in there
* Login to a server with the Globus connect binaries or run 
`docker run -it --rm hub.opensciencegrid.org/slate/globus-connect-v5-setup:0.1` to 
get a container with the necessary binaries
* Run `globus-connect-server login [endpoint-id]`
* Run `globus-connect-server storage-gateway create [options]` with the appropriate options
See [this page](https://docs.globus.org/globus-connect-server/v5/reference/storage-gateway/create/posix/) to 
get the options for a posix gateway if you are using ephemeral storage or a PVC. 
See [this page](https://docs.globus.org/globus-connect-server/v5/reference/storage-gateway/create/ceph/) to 
get options for a ceph (or S3) gateway.
* Run `globus-connect-server collection create [options]` with the appropriate options
to create a collection that will be shared from the endpoint.  See 
[this page](https://docs.globus.org/globus-connect-server/v5/reference/collection/create/) 
for more details on the options that Globus supports.

You can view endpoints that you control on the [globus website](https://app.globus.org/collections?scope=administered-by-me).

### Automatic Configuration (Experimental)

The following instructions allow SLATE to automatically create a storage gateway
and a storage collection on the deployed endpoint. ***Warning: this is experimental 
and may have bugs.***

In the application configuration, set `EndpointConfiguration` to `true` in order 
to enable the automatic configuration features.  Once that is done, you'll need
to configure the storage gateway settings and the collection settings.

#### Configuring the Storage Gateway

The storage gateway settings are configured using a section similar to the following
in the application setings. 

```yaml
StorageConfig:
  StorageType: "posix"  
  DisplayName: ""       
  AllowedUsers: []      
  DeniedUsers: []       
  Domain: []            
  RestrictPaths: false  
  CustomIdentityMapping: false  
  CephConfig:
      S3Endpoint: ""
      AdminKey:  ""
      SecretKey: ""
      Bucket: ""
  PosixConfig:
      DeniedGroups: []
      AllowedGroups: []
```

Currently only posix and ceph storage gateways can be automatically configured. 
So `StorageType` must be either `posix` or `ceph`.  The `DisplayName` should be
the endpoint's display name.  The `AllowedUsers` and `DeniedUsers` fields should 
give users that are allowed or denied from accessing the gateway.  An example 
of this would be 

```yaml
AllowedUsers:
  - allowedUser1
  - allowedUser2
DeniedUsers:
  - deniedUser1
```

The `Domain` field is a list of authorized domains for incoming users.  For example,
to allow users from `uchicago.edu` to access the storage gateway, use the following:

```yaml
Domain:
  - uchicago.edu
```

Multiple domains can be specified.  Set `RestrictPaths` to `true` in other to restrict 
access to specified paths on the storage gateway.  If this is enabled, then 
`GlobusRestrictConfig` must be set and point to a secret with a key called `restrictions`
that contains json specifying restricted paths on the server. The format of the restrictions
is given [here](https://docs.globus.org/globus-connect-server/v5/api/schemas/PathRestrictions_schema/).

If `CustomIdentityMapping` is enabled, then `GlobusIdentityConfig` must be set and
point to a secret with a key called `mapping`.  Similar to the `RestrictPaths` secret,
this key should point to json that specifies identity mapping for users.  [This page](https://docs.globus.org/globus-connect-server/v5/identity-mapping-guide/)
gives details on how to create an identity mapping.

For ceph gateways, `S3Endpoint` should be the URL to the ceph storage endpoint.  
The `AdminKey` and `SecretKey` fields should be credentials to an user with the 
permissions outlined [here](https://docs.globus.org/premium-storage-connectors/v5.4/ceph/).
The `Bucket` setting is the bucket that the storage gateway should use.

For posix gateways, `DeniedGroups` and `AllowedGroups` correspond to unix groups on
the container that should be denied or allowed access.  These fields should have a
similar format to the `AllowedUsers` and 'DeniedUsers` fields.

#### Configuring the Collection

The collection being served through the storage gateway is configured using the 
following settings in the application configuration:

```yaml
CollectionConfig:
  BasePath: "" 
  DisplayName: ""
  Department: ""
  Organization: ""
  ContactEmail: ""
  ContactInfo: ""
  Description: ""
  IdentityId: ""
  UserMessage: ""
```

The `BasePath` is the unix path that should serve as the base for the collection. E.g.
to serve files under `/mnt/storage/`, set `BasePath` to `/mnt/storage`.  `DisplayName`
is the name of the collection.  The other fields are optional with self-explanatory names. 
These fields will be displayed to users using globus connect when browsing or looking
up information about the collection. 
`IdentityId` is only needed if multiple globus accounts are associated with the storage gateway or 
collection.  In which case, you'll need to give the UUID of one of the accounts in this
field to act as the owner of the collection.


## Usage
For further instrucions on how to use globus please read this
[documentation](https://docs.globus.org/)
