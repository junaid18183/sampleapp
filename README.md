# Signing images and creating  SBOM using cosign

## Prerequisite

We will start with installing the tools, we are using following tools

- `nerdctl`  I have switched to nerdctl +rancher desktop as a replacement of Docker on my machine. But everything here should work with `docker` as well.
- `crane`  I will use this to inspect the layer of the image.
    
    Download using brew `brew install crane`
    
- `cosign`  you can install the latest version from the  https://github.com/sigstore/cosign
- `rekor-cli`  install the latest version from https://github.com/sigstore/rekor
- `syft` install using `brew install syft`  https://github.com/anchore/syft

For now we will do everything manually, later we an automate it in CI pipeline. 

## Build and Push the image

Let’s start with a very basic DockerFile 

```jsx
FROM alpine:3.15.0
LABEL maintainer="junaid18183@gmail.com"
```

Basically we are planning to get the alpine:3.15.0 and tag it our repository. 

Log in to your repository, I am using GitHub container registry 

```bash
$ echo $GHCR_TOKEN | nerdctl login  -u junaid18183 --password-stdin ghcr.io
Login Succeeded
```

Build and Push the image locally 

```bash
$ docker build -t ghcr.io/junaid18183/sampleapp:0.0.1 .
$ docker push ghcr.io/junaid18183/sampleapp:0.0.1
```

Get the digest of the pushed image and verify single tag is present in repository 

```bash
$ crane digest ghcr.io/junaid18183/sampleapp:0.0.1
sha256:b60cd6d6dafbaebc47e52e80ed6eb6e3d040888aac77a8eaa8e48b0743643108

$ crane ls ghcr.io/junaid18183/sampleapp
0.0.1
```

## Sign the Image

> We are going to use the **keyless signing so we we will set the environmental  variable`COSIGN_EXPERIMENTAL=true`**
> 

This will open  oauth2 URL from sigstore  where you can log in to sigstore using different providers, I opted for github 

```bash
COSIGN_EXPERIMENTAL=true cosign sign ghcr.io/junaid18183/sampleapp:0.0.1
Generating ephemeral keys...
Retrieving signed certificate...
Your browser will now be opened to:
https://oauth2.sigstore.dev/auth/auth?access_type=online&client_id=sigstore&code_challenge=FQdEAqSlWOxBXm-1LAFePulg53cIzuC-X5_4lXIH2ng&code_challenge_method=S256&nonce=23DsgaQ6dDH8UYFOi0P7SGrXFBI&redirect_uri=http%3A%2F%2Flocalhost%3A63959%2Fauth%2Fcallback&response_type=code&scope=openid+email&state=23DsgdQHo9WenYUvaSg30omBiPI
Successfully verified SCT...
tlog entry created with index: 1022921
Pushing signature to: ghcr.io/junaid18183/sampleapp
```

## Verify  the image

Now we can verify that the image is signed using verify command

```bash
COSIGN_EXPERIMENTAL=true cosign verify ghcr.io/junaid18183/sampleapp:0.0.1 | jq "."

Verification for ghcr.io/junaid18183/sampleapp:0.0.1 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - Any certificates were verified against the Fulcio roots.
[
  {
    "critical": {
      "identity": {
        "docker-reference": "ghcr.io/junaid18183/sampleapp"
      },
      "image": {
        "docker-manifest-digest": "sha256:b60cd6d6dafbaebc47e52e80ed6eb6e3d040888aac77a8eaa8e48b0743643108"
      },
      "type": "cosign container image signature"
    },
    "optional": {
      "Bundle": {
        "SignedEntryTimestamp": "MEUCIQD1XLsaYIH29EZ8r7RNdshRwhyXIBCcaAjDOcml/pVizwIgNT4mU3/jTUvPqQX5VXLGgXaGRL2cOrosWyPtzDcFzPc=",
        "Payload": {
          "body": "eyJhcGlWZXJzaW9uIjoiMC4wLjEiLCJraW5kIjoiaGFzaGVkcmVrb3JkIiwic3BlYyI6eyJkYXRhIjp7Imhhc2giOnsiYWxnb3JpdGhtIjoic2hhMjU2IiwidmFsdWUiOiI3ZDEwZjU2OTIwOGM5MTJhZDljYjZjZDc2NjY1ZjI5NjYwYmE3YTliNDNlY2FlNTdlMDQ1ODQxN2JjOTFiYjQxIn19LCJzaWduYXR1cmUiOnsiY29udGVudCI6Ik1FWUNJUURnT3FwOUVQS1VyRi8xZ1Jwc1dKQklIb3F5SW9ISkplcmR6UWtPdUdhVHNnSWhBSWNMZWtmMG1GVnpYd0N1MU5rbk1sWWVMRWVHWVZoSlNRQzRTQVdQRXFONSIsInB1YmxpY0tleSI6eyJjb250ZW50IjoiTFMwdExTMUNSVWRKVGlCRFJWSlVTVVpKUTBGVVJTMHRMUzB0Q2sxSlNVTktWRU5EUVdGMVowRjNTVUpCWjBsVVRFcG1lbVJDYm1wcFpWZ3ZaVGRNT0VwUk5rbDRlV3BHYkhwQlMwSm5aM0ZvYTJwUFVGRlJSRUY2UVhFS1RWSlZkMFYzV1VSV1VWRkxSWGQ0ZW1GWFpIcGtSemw1V2xNMWExcFlXWGhGVkVGUVFtZE9Wa0pCVFZSRFNFNXdXak5PTUdJelNteE5RalJZUkZSSmVRcE5SRVYzVGtSQk1rMXFaM2xOYkc5WVJGUkplVTFFUlhkT1JFRXlUWHBuZVUxV2IzZEZla1ZTVFVFNFIwRXhWVVZEYUUxSll6SnNibU16VW5aamJWVjNDbGRVUVZSQ1oyTnhhR3RxVDFCUlNVSkNaMmR4YUd0cVQxQlJUVUpDZDA1RFFVRlVjMlJwVkRFM05VOXZkQzlZVkdVMFJXMU1jeXRZUkdkelJERnlZa1VLZGtsUmJ6UkpkVGxSVlVWdlJWUXJWeTlaVERKRFMxTkpkMFpCWW0xM1QyWjBkMHd3Y0M4eU1WRnBSbGhLSzJJNFMyeEZURU54ZW1sdk5FaEhUVWxJUkFwTlFUUkhRVEZWWkVSM1JVSXZkMUZGUVhkSlNHZEVRVlJDWjA1V1NGTlZSVVJFUVV0Q1oyZHlRbWRGUmtKUlkwUkJla0ZOUW1kT1ZraFNUVUpCWmpoRkNrRnFRVUZOUWpCSFFURlZaRVJuVVZkQ1FsRTNVSGhoT1ZWelZYQlBUVzFVVFd3ck5ua3dXRTVZWmtjMVRIcEJaa0puVGxaSVUwMUZSMFJCVjJkQ1Vsa0tkMEkxWm10VlYyeGFjV3cyZWtwRGFHdDVURkZMYzFoR0sycEJaMEpuVGxaSVVrVkZSMVJCV0dkU1ZuRmtWelZvWVZkUmVFOUVSVFJOTUVKdVlsZEdjQXBpUXpWcVlqSXdkMHhCV1V0TGQxbENRa0ZIUkhaNlFVSkJVVkZsWVVoU01HTklUVFpNZVRsdVlWaFNiMlJYU1hWWk1qbDBUREo0ZGxveWJIVk1NamxvQ21SWVVtOU5RVzlIUTBOeFIxTk5ORGxDUVUxRVFUSm5RVTFIVlVOTlVVTkxOMEpNWmxobk0wNDFXbkJYTW1sVWEwSm1VU3RHV2pWT1ZFSmpUVXBTWjJnS01rRnFiREZWUkd3NFJVUlFSa2t2YmxOWVoxcFRUMEZDVFRkdVREVXpiME5OUWtSaVMyNUJUMlV2YWs5alRrVnJjalp4UTFGMEt6ZE5USEZHVEVkR0t3cHdWa2hVV2xaQlNtMXFRMHBITHl0aVEwRXJObm8wTjJKeWJGVTBha2R1V2tOM1BUMEtMUzB0TFMxRlRrUWdRMFZTVkVsR1NVTkJWRVV0TFMwdExRbz0ifX19fQ==",
          "integratedTime": 1641277705,
          "logIndex": 1022883,
          "logID": "c0d23d6ad406973f9559f3ba2d1ca01f84147d8ffc5b8445c224f98b9591801d"
        }
      },
      "Issuer": "https://github.com/login/oauth",
      "Subject": "junaid18183@gmail.com"
    }
  },
  {
    "critical": {
      "identity": {
        "docker-reference": "ghcr.io/junaid18183/sampleapp"
      },
      "image": {
        "docker-manifest-digest": "sha256:b60cd6d6dafbaebc47e52e80ed6eb6e3d040888aac77a8eaa8e48b0743643108"
      },
      "type": "cosign container image signature"
    },
    "optional": {
      "Bundle": {
        "SignedEntryTimestamp": "MEYCIQCGNZtAF7c2pvrridQ7IHOzHV0KJS0Uxfee+AEyZZPNxQIhAPorbtIo+T2GdD0fAiCAldV/TkDjy3dPOUF5nsDHmH76",
        "Payload": {
          "body": "eyJhcGlWZXJzaW9uIjoiMC4wLjEiLCJraW5kIjoiaGFzaGVkcmVrb3JkIiwic3BlYyI6eyJkYXRhIjp7Imhhc2giOnsiYWxnb3JpdGhtIjoic2hhMjU2IiwidmFsdWUiOiI3ZDEwZjU2OTIwOGM5MTJhZDljYjZjZDc2NjY1ZjI5NjYwYmE3YTliNDNlY2FlNTdlMDQ1ODQxN2JjOTFiYjQxIn19LCJzaWduYXR1cmUiOnsiY29udGVudCI6Ik1FVUNJRzExdU1qNE5RZU5FMlhZSTVsTE5HQmpUNmdqVjFyWUdkbkpkb2xudGFHdkFpRUFoMkJrd3dDdHhleDN0Qkx2ellkVXJEMWk1aGJ6MmZvK290VVF0Q0xTR1N3PSIsInB1YmxpY0tleSI6eyJjb250ZW50IjoiTFMwdExTMUNSVWRKVGlCRFJWSlVTVVpKUTBGVVJTMHRMUzB0Q2sxSlNVTktla05EUVdGNVowRjNTVUpCWjBsVlFVOTBSazFZZVVsWFVISjVUVEIzZGpsUE5sbEhWREpSUmxaRmQwTm5XVWxMYjFwSmVtb3dSVUYzVFhjS1MycEZWazFDVFVkQk1WVkZRMmhOVFdNeWJHNWpNMUoyWTIxVmRWcEhWakpOVWtWM1JIZFpSRlpSVVVSRmQyaDZZVmRrZW1SSE9YbGFWRUZsUm5jd2VRcE5ha0Y0VFVSUmQwNTZRVFJOYW14aFJuY3dlVTFxUVhoTlJGRjNUbnBGTkUxcWFHRk5RazE0UlZSQlVFSm5UbFpDUVc5VVEwaE9jRm96VGpCaU0wcHNDazFHYTNkRmQxbElTMjlhU1hwcU1FTkJVVmxKUzI5YVNYcHFNRVJCVVdORVVXZEJSVVZEYjNjcmRHbHZZVTFGVFZOV2FXaHVURlpCTVhwWE16Qk5SRGdLYmtOQ1NqQlVTV0Y0YW5JdmRHSnFja1JyVTNaR2JHVTNRMFpyY1VKb01tWldNVVJMVDFsWFpXOTRNM2h1ZDNkT1VFbFZNRVEyZVdaeVlVOUNlR3BEUWdwM2VrRlBRbWRPVmtoUk9FSkJaamhGUWtGTlEwSTBRWGRGZDFsRVZsSXdiRUpCZDNkRFoxbEpTM2RaUWtKUlZVaEJkMDEzUkVGWlJGWlNNRlJCVVVndkNrSkJTWGRCUkVGa1FtZE9Wa2hSTkVWR1oxRlZaVEpXT0VoTVlXTXhXVnBxWW01aVVWUmhMMlZaVXpkTU9HMVJkMGgzV1VSV1VqQnFRa0puZDBadlFWVUtWMDFCWlZnMVJrWndWMkZ3WlhONVVXOWFUV2t3UTNKR2VHWnZkMGxCV1VSV1VqQlNRa0pyZDBZMFJWWmhibFoxV1Zkc2EwMVVaM2hQUkU1QldqSXhhQXBoVjNkMVdUSTVkRTFEZDBkRGFYTkhRVkZSUW1jM09IZEJVVVZGU0cxb01HUklRbnBQYVRoMldqSnNNR0ZJVm1sTWJVNTJZbE01YzJJeVpIQmlhVGwyQ2xsWVZqQmhSRUZMUW1kbmNXaHJhazlRVVZGRVFYZE9jRUZFUW0xQmFrVkJjMUU1Y1RkMFZIaHliSGg2VG1KNVVUWlNSVnAzYkc5MFQzQm9PRmN6Y21NS1VVVkZSMnhvYTFBemNIRlZhMVU0TXpOWlNscDJjakpST0RkUE1XUXJiSFZCYWtWQmJWcHBRMVkyYUVFd2NESkRaRlZEYlZKblNIQmhXazAxY2xocFNBcHdjSGxOZUhoWFduZGtiRTVUWjFKSmEyZ3ZVREJoV25sbmN5dFhlblFyTXpKM2VEUUtMUzB0TFMxRlRrUWdRMFZTVkVsR1NVTkJWRVV0TFMwdExRbz0ifX19fQ==",
          "integratedTime": 1641280112,
          "logIndex": 1022921,
          "logID": "c0d23d6ad406973f9559f3ba2d1ca01f84147d8ffc5b8445c224f98b9591801d"
        }
      },
      "Issuer": "https://github.com/login/oauth",
      "Subject": "junaid18183@gmail.com"
    }
  }
]
```

Since I signed it multiple times there are multiple Signed entries, and we can confirm that the Issuer and Subject are valid. 

We can also check the transparency log using `rekor-cli` , just provide the log index from the above verify output.

```bash
rekor-cli get --log-index 1022883
LogID: c0d23d6ad406973f9559f3ba2d1ca01f84147d8ffc5b8445c224f98b9591801d
Index: 1022883
IntegratedTime: 2022-01-04T06:28:25Z
UUID: 78b2e6083d81a40fd4b042ff5f6056bc7472ceb9be283b6989cb89046d6f1cdf
Body: {
  "HashedRekordObj": {
    "data": {
      "hash": {
        "algorithm": "sha256",
        "value": "7d10f569208c912ad9cb6cd76665f29660ba7a9b43ecae57e0458417bc91bb41"
      }
    },
    "signature": {
      "content": "MEYCIQDgOqp9EPKUrF/1gRpsWJBIHoqyIoHJJerdzQkOuGaTsgIhAIcLekf0mFVzXwCu1NknMlYeLEeGYVhJSQC4SAWPEqN5",
      "publicKey": {
        "content": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNKVENDQWF1Z0F3SUJBZ0lUTEpmemRCbmppZVgvZTdMOEpRNkl4eWpGbHpBS0JnZ3Foa2pPUFFRREF6QXEKTVJVd0V3WURWUVFLRXd4emFXZHpkRzl5WlM1a1pYWXhFVEFQQmdOVkJBTVRDSE5wWjNOMGIzSmxNQjRYRFRJeQpNREV3TkRBMk1qZ3lNbG9YRFRJeU1ERXdOREEyTXpneU1Wb3dFekVSTUE4R0ExVUVDaE1JYzJsbmMzUnZjbVV3CldUQVRCZ2NxaGtqT1BRSUJCZ2dxaGtqT1BRTUJCd05DQUFUc2RpVDE3NU9vdC9YVGU0RW1McytYRGdzRDFyYkUKdklRbzRJdTlRVUVvRVQrVy9ZTDJDS1NJd0ZBYm13T2Z0d0wwcC8yMVFpRlhKK2I4S2xFTENxemlvNEhHTUlIRApNQTRHQTFVZER3RUIvd1FFQXdJSGdEQVRCZ05WSFNVRUREQUtCZ2dyQmdFRkJRY0RBekFNQmdOVkhSTUJBZjhFCkFqQUFNQjBHQTFVZERnUVdCQlE3UHhhOVVzVXBPTW1UTWwrNnkwWE5YZkc1THpBZkJnTlZIU01FR0RBV2dCUlkKd0I1ZmtVV2xacWw2ekpDaGt5TFFLc1hGK2pBZ0JnTlZIUkVFR1RBWGdSVnFkVzVoYVdReE9ERTRNMEJuYldGcApiQzVqYjIwd0xBWUtLd1lCQkFHRHZ6QUJBUVFlYUhSMGNITTZMeTluYVhSb2RXSXVZMjl0TDJ4dloybHVMMjloCmRYUm9NQW9HQ0NxR1NNNDlCQU1EQTJnQU1HVUNNUUNLN0JMZlhnM041WnBXMmlUa0JmUStGWjVOVEJjTUpSZ2gKMkFqbDFVRGw4RURQRkkvblNYZ1pTT0FCTTduTDUzb0NNQkRiS25BT2Uvak9jTkVrcjZxQ1F0KzdNTHFGTEdGKwpwVkhUWlZBSm1qQ0pHLytiQ0ErNno0N2JybFU0akduWkN3PT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
      }
    }
  }
}
```

What happened under the hood ?

the `cosign` uploaded the signature of the image with the name `{sha256 of image}.sig` to the same repo.  We can verify using `crane`

```bash
$ crane ls ghcr.io/junaid18183/sampleapp
0.0.1
sha256-b60cd6d6dafbaebc47e52e80ed6eb6e3d040888aac77a8eaa8e48b0743643108.sig

$ crane digest ghcr.io/junaid18183/sampleapp:0.0.1
sha256:b60cd6d6dafbaebc47e52e80ed6eb6e3d040888aac77a8eaa8e48b0743643108

 $ crane ls ghcr.io/junaid18183/sampleapp
0.0.1
sha256-b60cd6d6dafbaebc47e52e80ed6eb6e3d040888aac77a8eaa8e48b0743643108.sig
```

## Generate and upload the SBOM

We will use the `syft` to generate the SBOM and once its generated we will attach to image using `cosign` 

Let’s first generate the SBOM 

```bash
$ syft packages ghcr.io/junaid18183/sampleapp:0.0.1 -o spdx  > latest.spdx
 ✔ Parsed image
 ✔ Cataloged packages      [14 packages]
```

The SBOM contains all the packages in the image 

```bash
$ cat latest.spdx
SPDXVersion: SPDX-2.2
DataLicense: CC0-1.0
SPDXID: SPDXRef-DOCUMENT
DocumentName: ghcr.io/junaid18183/sampleapp-0.0.1
DocumentNamespace: https://anchore.com/syft/image/ghcr.io/junaid18183/sampleapp-0.0.1-0353fda9-4263-4185-af00-0a209df0f246
LicenseListVersion: 3.15
Creator: Organization: Anchore, Inc
Creator: Tool: syft-0.34.0
Created: 2022-01-04T07:30:50Z

##### Package: alpine-baselayout

PackageName: alpine-baselayout
SPDXID: SPDXRef-Package-apk-alpine-baselayout
PackageVersion: 3.2.0-r18
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: GPL-2.0-only
PackageLicenseDeclared: GPL-2.0-only
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine-baselayout:alpine-baselayout:3.2.0-r18:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine-baselayout:alpine_baselayout:3.2.0-r18:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine_baselayout:alpine-baselayout:3.2.0-r18:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine_baselayout:alpine_baselayout:3.2.0-r18:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine:alpine-baselayout:3.2.0-r18:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine:alpine_baselayout:3.2.0-r18:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/alpine-baselayout@3.2.0-r18?arch=x86_64

##### Package: alpine-keys

PackageName: alpine-keys
SPDXID: SPDXRef-Package-apk-alpine-keys
PackageVersion: 2.4-r1
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: MIT
PackageLicenseDeclared: MIT
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine-keys:alpine-keys:2.4-r1:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine-keys:alpine_keys:2.4-r1:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine_keys:alpine-keys:2.4-r1:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine_keys:alpine_keys:2.4-r1:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine:alpine-keys:2.4-r1:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:alpine:alpine_keys:2.4-r1:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/alpine-keys@2.4-r1?arch=x86_64

##### Package: apk-tools

PackageName: apk-tools
SPDXID: SPDXRef-Package-apk-apk-tools
PackageVersion: 2.12.7-r3
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: GPL-2.0-only
PackageLicenseDeclared: GPL-2.0-only
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:apk-tools:apk-tools:2.12.7-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:apk-tools:apk_tools:2.12.7-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:apk_tools:apk-tools:2.12.7-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:apk_tools:apk_tools:2.12.7-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:apk:apk-tools:2.12.7-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:apk:apk_tools:2.12.7-r3:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/apk-tools@2.12.7-r3?arch=x86_64

##### Package: busybox

PackageName: busybox
SPDXID: SPDXRef-Package-apk-busybox
PackageVersion: 1.34.1-r3
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: GPL-2.0-only
PackageLicenseDeclared: GPL-2.0-only
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:busybox:busybox:1.34.1-r3:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/busybox@1.34.1-r3?arch=x86_64

##### Package: ca-certificates-bundle

PackageName: ca-certificates-bundle
SPDXID: SPDXRef-Package-apk-ca-certificates-bundle
PackageVersion: 20191127-r7
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: MPL-2.0 AND MIT
PackageLicenseDeclared: MPL-2.0 AND MIT
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca-certificates-bundle:ca-certificates-bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca-certificates-bundle:ca_certificates_bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca_certificates_bundle:ca-certificates-bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca_certificates_bundle:ca_certificates_bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca-certificates:ca-certificates-bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca-certificates:ca_certificates_bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca_certificates:ca-certificates-bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca_certificates:ca_certificates_bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca:ca-certificates-bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ca:ca_certificates_bundle:20191127-r7:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/ca-certificates-bundle@20191127-r7?arch=x86_64

##### Package: libc-utils

PackageName: libc-utils
SPDXID: SPDXRef-Package-apk-libc-utils
PackageVersion: 0.7.2-r3
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: BSD-2-Clause AND BSD-3-Clause
PackageLicenseDeclared: BSD-2-Clause AND BSD-3-Clause
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:libc-utils:libc-utils:0.7.2-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:libc-utils:libc_utils:0.7.2-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:libc_utils:libc-utils:0.7.2-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:libc_utils:libc_utils:0.7.2-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:libc:libc-utils:0.7.2-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:libc:libc_utils:0.7.2-r3:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/libc-utils@0.7.2-r3?arch=x86_64

##### Package: libcrypto1.1

PackageName: libcrypto1.1
SPDXID: SPDXRef-Package-apk-libcrypto1.1
PackageVersion: 1.1.1l-r7
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: OpenSSL
PackageLicenseDeclared: OpenSSL
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:libcrypto1.1:libcrypto1.1:1.1.1l-r7:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/libcrypto1.1@1.1.1l-r7?arch=x86_64

##### Package: libretls

PackageName: libretls
SPDXID: SPDXRef-Package-apk-libretls
PackageVersion: 3.3.4-r2
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: ISC
PackageLicenseDeclared: ISC
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:libretls:libretls:3.3.4-r2:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/libretls@3.3.4-r2?arch=x86_64

##### Package: libssl1.1

PackageName: libssl1.1
SPDXID: SPDXRef-Package-apk-libssl1.1
PackageVersion: 1.1.1l-r7
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: OpenSSL
PackageLicenseDeclared: OpenSSL
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:libssl1.1:libssl1.1:1.1.1l-r7:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/libssl1.1@1.1.1l-r7?arch=x86_64

##### Package: musl

PackageName: musl
SPDXID: SPDXRef-Package-apk-musl
PackageVersion: 1.2.2-r7
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: MIT
PackageLicenseDeclared: MIT
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:musl:musl:1.2.2-r7:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/musl@1.2.2-r7?arch=x86_64

##### Package: musl-utils

PackageName: musl-utils
SPDXID: SPDXRef-Package-apk-musl-utils
PackageVersion: 1.2.2-r7
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: MIT
PackageLicenseDeclared: MIT
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:musl-utils:musl-utils:1.2.2-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:musl-utils:musl_utils:1.2.2-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:musl_utils:musl-utils:1.2.2-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:musl_utils:musl_utils:1.2.2-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:musl:musl-utils:1.2.2-r7:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:musl:musl_utils:1.2.2-r7:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/musl-utils@1.2.2-r7?arch=x86_64

##### Package: scanelf

PackageName: scanelf
SPDXID: SPDXRef-Package-apk-scanelf
PackageVersion: 1.3.3-r0
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: GPL-2.0-only
PackageLicenseDeclared: GPL-2.0-only
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:scanelf:scanelf:1.3.3-r0:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/scanelf@1.3.3-r0?arch=x86_64

##### Package: ssl_client

PackageName: ssl_client
SPDXID: SPDXRef-Package-apk-ssl_client
PackageVersion: 1.34.1-r3
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: GPL-2.0-only
PackageLicenseDeclared: GPL-2.0-only
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ssl-client:ssl-client:1.34.1-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ssl-client:ssl_client:1.34.1-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ssl_client:ssl-client:1.34.1-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ssl_client:ssl_client:1.34.1-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ssl:ssl-client:1.34.1-r3:*:*:*:*:*:*:*
ExternalRef: SECURITY cpe23Type cpe:2.3:a:ssl:ssl_client:1.34.1-r3:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/ssl_client@1.34.1-r3?arch=x86_64

##### Package: zlib

PackageName: zlib
SPDXID: SPDXRef-Package-apk-zlib
PackageVersion: 1.2.11-r3
PackageDownloadLocation: NOASSERTION
FilesAnalyzed: false
PackageLicenseConcluded: Zlib
PackageLicenseDeclared: Zlib
PackageCopyrightText: NOASSERTION
ExternalRef: SECURITY cpe23Type cpe:2.3:a:zlib:zlib:1.2.11-r3:*:*:*:*:*:*:*
ExternalRef: PACKAGE_MANAGER purl pkg:alpine/zlib@1.2.11-r3?arch=x86_64
```

Now lets attach the SBOM of the image to the registry so that any one can download the SBOM later 

```bash
$ cosign attach sbom --sbom latest.spdx ghcr.io/junaid18183/sampleapp:0.0.1
Uploading SBOM file for [ghcr.io/junaid18183/sampleapp:0.0.1] to [ghcr.io/junaid18183/sampleapp:sha256-b60cd6d6dafbaebc47e52e80ed6eb6e3d040888aac77a8eaa8e48b0743643108.sbom] with mediaType [text/spdx].
```

This basically uploaded the SBOM to registry directly , we can confirm using `crane`

```bash
$ crane ls ghcr.io/junaid18183/sampleapp
0.0.1
sha256-b60cd6d6dafbaebc47e52e80ed6eb6e3d040888aac77a8eaa8e48b0743643108.sig
sha256-b60cd6d6dafbaebc47e52e80ed6eb6e3d040888aac77a8eaa8e48b0743643108.sbom
```

Any one can download the SBOM directly using `cosign` 

```bash
rancher-desktop sampleapp main ❯ cosign download sbom ghcr.io/junaid18183/sampleapp:0.0.1
Found SBOM of media type: text/spdx
SPDXVersion: SPDX-2.2
DataLicense: CC0-1.0
SPDXID: SPDXRef-DOCUMENT
DocumentName: ghcr.io/junaid18183/sampleapp-0.0.1
DocumentNamespace: https://anchore.com/syft/image/ghcr.io/junaid18183/sampleapp-0.0.1-0353fda9-4263-4185-af00-0a209df0f246
LicenseListVersion: 3.15
Creator: Organization: Anchore, Inc
Creator: Tool: syft-0.34.0
Created: 2022-01-04T07:30:50Z
....
```



# CI Pipeline using Github actions

 We will perform same actions using CI pipeline using github actions achieving the Hermetic builds for the [SLSA](https://slsa.dev/spec/v0.1/levels). 

I have created the sample repository https://github.com/junaid18183/sampleapp so that we can see the CI in action. 

The gist of the pipeline is this [workflow](https://github.com/junaid18183/sampleapp/blob/main/.github/workflows/docker-publish.yml) file,  lets check in detail what each step is doing,

First three  steps are pretty obvious, we are 

- getting the code via checkout action
- Logging into the Github Container Registry ( the GHCR_ACCESS_TOKEN is the secret created in the repo containing my Personal Access Token )
- Building and Pushing the image to our registry.

- Next we are creating the SBOM using the [anchore/sbom-action](https://github.com/anchore/sbom-action)  we are also creating artefact  named `sbom.spdx` so that any following job can consume it  and its also available in github workflow run outputs.
- Next step we download the cosign using the official [sigstore/cosign-installer](https://github.com/sigstore/cosign-installer) action.
- And finally we are signing the image and attaching the SBOM to the image.

Few important points to note though, 

We are pushing the image as github commit sha not a particular tag, Since the commit sha is immutable so that we are 100% sure on the verification part that the image in question is same. 

```bash
rancher-desktop sampleapp main ❯ COSIGN_EXPERIMENTAL=true cosign verify ghcr.io/junaid18183/sampleapp:67bb91efb62bfae268bcd0a243a10d48fde80559 | jq "."

Verification for ghcr.io/junaid18183/sampleapp:67bb91efb62bfae268bcd0a243a10d48fde80559 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - Any certificates were verified against the Fulcio roots.
[
  {
    "critical": {
      "identity": {
        "docker-reference": "ghcr.io/junaid18183/sampleapp"
      },
      "image": {
        "docker-manifest-digest": "sha256:3408cd56925524ab26302d4c488c5e8fbce357d7dfa1bb03994780b47697f49b"
      },
      "type": "cosign container image signature"
    },
    "optional": {
      "Bundle": {
        "SignedEntryTimestamp": "MEQCIBrzgx7XaYGkDzkpvxJS+locgn1SaTGBd0gDzLWVwoqRAiAxzhQ0nhSk75I7O9h2FWj0JFXDzwo/K/8nNPWal83scg==",
        "Payload": {
          "body": "eyJhcGlWZXJzaW9uIjoiMC4wLjEiLCJraW5kIjoiaGFzaGVkcmVrb3JkIiwic3BlYyI6eyJkYXRhIjp7Imhhc2giOnsiYWxnb3JpdGhtIjoic2hhMjU2IiwidmFsdWUiOiJiZjFkYWI1MzRjOTU0YWU4ZWJkNTJmNzU5NzIxNDdkNWRmM2QyMWQ4MjZlZGY2NTgzMzVkMzAzODU3YjFlN2E4In19LCJzaWduYXR1cmUiOnsiY29udGVudCI6Ik1FUUNJRUlIdVhTM0g1S0ZPWGZlL1EyTzlabXprL2o5dStvVllaaHpFc2VmQy81a0FpQlZScVl1NTU3NlRNNDdaTXdzYy9KMHQ5WXdXZGRVVU1wckQzMWpTbWg4a2c9PSIsInB1YmxpY0tleSI6eyJjb250ZW50IjoiTFMwdExTMUNSVWRKVGlCRFJWSlVTVVpKUTBGVVJTMHRMUzB0Q2sxSlNVTjVWRU5EUVdzclowRjNTVUpCWjBsVlFVcExOQ3MyUmpOMFIzZERkVGhDWTJOeU1XTjBOR3cxVDBrMGQwTm5XVWxMYjFwSmVtb3dSVUYzVFhjS1MycEZWazFDVFVkQk1WVkZRMmhOVFdNeWJHNWpNMUoyWTIxVmRWcEhWakpOVWtWM1JIZFpSRlpSVVVSRmQyaDZZVmRrZW1SSE9YbGFWRUZsUm5jd2VRcE5ha0Y0VFVSUmVFMXFRWGxOVkdoaFJuY3dlVTFxUVhoTlJGRjRUV3BGZVUxVVpHRk5RazE0UlZSQlVFSm5UbFpDUVc5VVEwaE9jRm96VGpCaU0wcHNDazFHYTNkRmQxbElTMjlhU1hwcU1FTkJVVmxKUzI5YVNYcHFNRVJCVVdORVVXZEJSVE5VTmpKa1pGTkplRUpZVkZOMGVVTkVZV2d3Um1ScEszaG1ZV1VLY0dWdkwySXhZV0paVTB0VmMxbHFZVTEwTVhGT01sbExNamxQWVd0WWFFUnZjalUxVG14QlpFRnVUVXBVWTB0UE9HNDNkVkJ2UmxZdlMwOURRVmRuZHdwblowWnJUVUUwUjBFeFZXUkVkMFZDTDNkUlJVRjNTVWhuUkVGVVFtZE9Wa2hUVlVWRVJFRkxRbWRuY2tKblJVWkNVV05FUVhwQlRVSm5UbFpJVWsxQ0NrRm1PRVZCYWtGQlRVSXdSMEV4VldSRVoxRlhRa0pUTUVSRlFXazJhRGwwZWxCWWNFVXJibkZEU1RWMVJtbDROazVVUVdaQ1owNVdTRk5OUlVkRVFWY0taMEpTV1hkQ05XWnJWVmRzV25Gc05ucEtRMmhyZVV4UlMzTllSaXRxUW05Q1owNVdTRkpGUlZsVVFtWm9iREZ2WkVoU2QyTjZiM1pNTW1Sd1pFZG9NUXBaYVRWcVlqSXdkbUZ1Vm5WWlYyeHJUVlJuZUU5RVRYWmpNa1owWTBkNGJGbFlRbmRNZVRWdVlWaFNiMlJYU1haa01qbDVZVEphYzJJelpIcE1NbEoyQ2xreWRHeGphVEYzWkZkS2MyRllUbTlNYm14MFlrVkNlVnBYV25wTU1taHNXVmRTZWt3eU1XaGhWelIzVDFGWlMwdDNXVUpDUVVkRWRucEJRa0ZSVVhJS1lVaFNNR05JVFRaTWVUa3dZakowYkdKcE5XaFpNMUp3WWpJMWVreHRaSEJrUjJneFdXNVdlbHBZU21waU1qVXdXbGMxTUV4dFRuWmlWRUZUUW1kdmNncENaMFZGUVZsUEwwMUJSVU5DUVZKM1pGaE9iMDFFV1VkRGFYTkhRVkZSUW1jM09IZEJVVTFGUzBSWk0xbHRTVFZOVjFadFdXcFplVmx0V21oYVZFa3lDazlIU21wYVJFSm9UV3BSZWxsVVJYZGFSRkUwV20xU2JFOUVRVEZPVkd0M1EyZFpTVXR2V2tsNmFqQkZRWGROUkdGQlFYZGFVVWwzV0ZJM09XRkJRbWNLUlM5R1prOXpNa0ZsUVVkUGRubDJVREVyUnpKUmRrOWtXbE5HUVZoUmJEazRVVWxUV0d4UUx6VmFXR1ZFZW1OMlVtRTVRekJaZEM5QmFrVkJlVm96TmdwNE1VRldMMEZEYjFCVlNYQjBiMFkzWW1NM2NsaElabWszZFdaVU5WRXljRGt3UW0xc1VIUnpPRXR3ZWxWTGVXaEpOV0pQYW05b01rWnBhMFlLTFMwdExTMUZUa1FnUTBWU1ZFbEdTVU5CVkVVdExTMHRMUW89In19fX0=",
          "integratedTime": 1641297739,
          "logIndex": 1023447,
          "logID": "c0d23d6ad406973f9559f3ba2d1ca01f84147d8ffc5b8445c224f98b9591801d"
        }
      },
      "Issuer": "https://token.actions.githubusercontent.com",
      "Subject": "https://github.com/junaid18183/sampleapp/.github/workflows/docker-publish.yml@refs/heads/main"
    }
  }
]
```

And next important item to note is , 

Since we are using **keyless mode of the cosign signing** we have to get the  Github Actions OIDC tokens. This is done by adding the `id-token` [permission](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token) to our [job](https://github.com/junaid18183/sampleapp/blob/main/.github/workflows/docker-publish.yml#L9) 

## Reference

- [https://chainguard.dev/posts/2021-12-01-zero-friction-keyless-signing](https://chainguard.dev/posts/2021-12-01-zero-friction-keyless-signing)
- [https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#updating-your-actions-for-oidc](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#updating-your-actions-for-oidc)