# CertPub Verifier

Command line tool, available as Docker image, for verification of setups of CertPub Locator and CertPub Publisher services.


## Verify a participant

To verify a participant, simply run the following:

```shell
docker run --rm -it certpub/verifier -p 0192:984851006
```

The `-p` is used to set the participant identifier used. The default configuration runs towards the production environment, however use `-m test` to switch to the test environment.