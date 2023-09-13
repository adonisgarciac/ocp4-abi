Ansible code to install an Openshift 4.X cluster using the [agent-based](https://cloud.redhat.com/blog/meet-the-new-agent-based-openshift-installer-1) installer method.

# Run the Ansible based installer

```bash
ansible-playbook -vvv -i inventory.yaml install-openshift.yaml
``` 

TODO:
- Add other installation rathern than only SNO
- Add other platforms than vSphere
- Use Eexecution Envs to run the installer

