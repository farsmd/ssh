# SSH User Manager

SSH User Manager is a script designed to manage SSH users on a Linux server.

## Features
- Add new SSH users
- Remove existing SSH users
- List all SSH users
- Change passwords for SSH users
- Backup and restore user data
- Log user management activities
- Customize SSH user settings
- Monitor SSH login attempts


## Installation

To install the SSH User Manager on an Ubuntu server, run the following command:

```sh
curl -s https://raw.githubusercontent.com/farsmd/ssh/main/install.sh | bash
```
After installation, you can manage SSH users using the following commands:

To add a user:

```
./user_management.sh add <username>
```
To remove a user:

```
./user_management.sh remove <username>
```
To list all users:

```
./user_management.sh list
```
To change a user's password:

```
./user_management.sh passwd <username>
```
Contributing

Feel free to fork this repository and submit pull requests.

License

This project is licensed under the MIT License.

