# mirr.OS API backend 

## Prerequisites
- Ruby >= 2.6.3
- mySQL >= 5.7

## Setup

Clone this repository to your local machine and install dependencies:
```shell script
git clone https://gitlab.com/glancr/mirros_api.git
cd mirros_api
bundle install --path vendor/bundle
```

By default, mirr.OS will use the MySQL root user account with the password `glancr` to avoid permission issues. If you'd rather not change the root user password, or if you want to use a separate user, please change the credentials in `config/database.yml` and ensure the account has permission to create a database.

Assuming you have MySQL running on localhost and have assigned a password for the `root` user during installation:

```shell script
mysql -u root -p # enter password when prompted
```
At the MySQL prompt, change your root user password to `glancr`:
```mysql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'glancr';
FLUSH PRIVILEGES;
```

Now, let's create and seed the database.
```shell script
bin/rails db:setup
```

Yay! You're all set to run mirr.OS setup process. Either launch your local [settings app](https://gitlab.com/glancr/mirros_settings/) in a browser and configure mirr.OS through the UI, or run the setup task:
```shell script
# If you omit the brackets, it'll attempt to use your git username / email instead. 
bin/rails mirros:dev:run_setup[Your Name, email@example.com]
```

You can change all settings later in the UI.

## Starting the server

```shell script
# cd /path/to/mirros_api
bin/rails server
```
This will start up Rails on `http://localhost:3000`. To stop the server, press `Ctrl+C`.

### Running a console for testing
Note: This does not start the scheduler, which would cause thread issues otherwise.
```shell script
bin/rails console
```
