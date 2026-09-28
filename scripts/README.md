# Scripts _VERSION 7_
Maybe unnecessary but I like the idea! Seemed a bit more convenient that typing it all out.

These functions must be run with the virtual environment activated, and should always be unset after.
Using `deactivate` will handle this, otherwise `source scripts/deactivate.sh` is a backup.


## Usage

1. Activate the environment:
```
source scripts/activate.sh
```
_Or `activate` — I have an alias in ~/.bash_aliases.sh that 'activate="source scripts/activate'_

2. Call the command to generate all configuration lines:
```
generate-configs
```

3. Call the command to ssh and update the configurations:
```
ssh-update-configs
```
_Should probs be careful with the this one..._

4. Call the command to clear all the configurations:
```
ssh-clear-configs
```

5. Alternatively, do it all in one go:
```
ssh-refresh
```
**Definitely be careful with this one.**

6. SSH to a pair of routers/hosts and open a split pane:
```
ssh-goto-pair LOND HAML <'router' or 'host'>
```

7. Run tests on a pair of routers/hosts and save the output:
```
ssh-test LOND HAML
```

8. There's also the individual functions that run an unnecessary amount of tests on everything:
- `ssh-ping`
- `ssh-iperf` (iperf3)
- `ssh-traceroute`
- And more in scripts/activate, but they all call the same script 'ssh_measure.sh'

**All of the above is dependent on:**
- Tmux is installed, e.g., `brew install tmux`
- Your ssh key is in '/Users/username/.ssh/id_rsa' (edit this path in ssh_tmux.sh if not)
- There is some kind of ssh config file that handles the jump to proxy.

