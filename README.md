# kubectl secret decode plugin

Created a simple kubectl plugin to decode values in secrets configs.

- drop kubectl-decode anywhere in your PATH (ie. ~/bin/kubectl-decode)
- make executable chmod +x ~/bin/kubectl-decode
- run command and pass in name of secret

```
> kubectl decode docker-registry
{
  ".dockercfg": "{\n  \"docker.my-registry.io\": {\n    \"auth\": \"bWEtdXnononononononoM2MDA=\",\n    \"email\": \"not@val.id\"\n  },\n  \"docker.my-registry.i:5000\": {\n    \"auth\": \"a2V5Y2hlc3RfononononononmFmYzQ3Yjk0OGY=\",\n    \"email\": \"not@val.id\"\n  }\n}\n"
}
```



Ref. https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/#writing-kubectl-plugins