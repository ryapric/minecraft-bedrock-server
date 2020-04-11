Minecraft Bedrock Server Deployment Tools
=========================================

Deploy your very own Minecraft Bedrock server to play with friends!

- `ansible/` has all the Ansible-related tooling

- `cloudformation/` has any CloudFormation (CFN) Stacks (as `.yaml` files)
  needed to manage the infrastructure for the Bedrock server.

Much of the paramterization in this codebase depends not on the individual
tools' templating engines, but on Python's Jinja2 library. This should make
developer maintenance easier, as it relegates a lot of the dynamism lift to a
single tool, and indeed a single configuration file, `config.yaml`.

How to Use
----------

Note that this user guide is targeted towards those deploying everything from a
UNIX-alike system, like macOS or GNU/Linux operating systems. You specific
results may vary if using Windows.

### Prerequisites:

- Deployment of software/configuration management:

  - GNU Make

  - jq
  
  - Python 3

  - Python 3's package manager, `pip3`

    - Once you have `pip` installed, run `pip3 install -r requirements.txt`.
      Note that you may need to pass the `--user` flag if on a Debian-based
      system.

- Infrastructure/hosting:

  - An AWS account

  - An AWS EC2 Key Pair (CFN can't create/manage these for you, unlike
    Terraform, but whatever)

  - An IAM User or assumable Role (User is easier, if it's just for this use
    case)

  - Appropriate IAM permissions for your User to manage the lifecycle of the CFN
    resources

Developer Notes
---------------

- Anything being rendered will need to still have `_jinja` in the name.
