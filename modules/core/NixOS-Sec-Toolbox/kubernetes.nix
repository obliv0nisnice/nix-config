# Kubernetes infrastructure

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cfripper
    cirrusgo
    kdigger
    kube-score
    kubeaudit
    kubestroyer
    kubescape
    popeye
  ];
}
