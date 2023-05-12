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

* Login on globus.org and in Settings>Developers, select the project that the endpoint will be registered in
* Add an app and under the type, select 'Register a Globus Connect Server'
* Create a new registration with the appropriate fields 
* Make sure to record the client uuid since this will be needed
* Create a new client secret and record the secret (this is the only time it will be displayed)
* On a system with [globus connect 5.4 installed](https://docs.globus.org/globus-connect-server/v5/quickstart/#gcsv5-install), run 

  ```shell
  $ globus-connect-server endpoint setup [endpoint_name] \
        --contact-email [email] -o [globus_id] --organization [org] \
        -c [client_uuid]
  ``` 

  replacing `[endpoint_name]` with your endpoint's name, `[email]` with your contact email, 
  `[globus_id]` with your globus id (e.g. `sthapa@globusid.org`), `[org]` with your organization, and
  `[client_uuid]` with the client uuid you got from the globus.org website.
* The setup will request the secret that you generated and then create a deployment-key.json file that you *must* keep 

Create a new file with the contents:

```
GLOBUS_CLIENT_ID=<client_uuid>
GLOBUS_CLIENT_SECRET=<secret>
DEPLOYMENT_KEY=<contents of deployment-key.json>

```

And then create the credential with:


```shell
$ slate secret create <secret-name> --group <group> --cluster <cluster> \
    --from-env-file <filename>
```


### Generating the passwd(5) file 
This chart will consume a file in the format of /etc/passwd, with the notable
exception that the second field must contain an encrypted password hash. This
hash will be stored as a SLATE secret (re-encrypted in DynamoDB) and the
encrypted hash be visible to any user of your namespace and the administrator
of the SLATE cluster upon which you are deploying GCSv5. 

You will need to provide an extended passwd(5)-format file with the 
users' X509 distinguished name (DN) in the final field, e.g.:

```
   slateci:x:1001:1001:SLATE CI:/home/slateci:/DC=org/DC=cilogon/C=US/O=UNIX University/CN=Charlie Root A1234
```

The encrypted password hash can be generated via:

```
openssl passwd -1
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

password    This is either the encrypted  user  password,  an  asterisk
            (*),  or the letter 'x'.  (See pwconv(8) for an explanation
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

### Deploying 
To deploy the chart, first get the values file and store it:

```
slate app get-conf --dev globus-connect-v5 > gcs.yaml
```

Edit to your liking (notably the GlobusPasswdSecret and GlobusConfigFile must match what you have created in previous steps) and deploy with:

```
slate app install --cluster <cluster> --group <group> globus-connect-v5 --conf gcs.yaml
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
 
## Usage
For further instrucions on how to use globus please read this
[documentation](https://docs.globus.org/)
