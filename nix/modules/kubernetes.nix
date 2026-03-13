{ config, pkgs, lib, ... }:

{
  # Single node k3s (works now, can scale to HA later)
  services.k3s = {
    enable = true;
    role = "server";
    
    #tokenFile = "/etc/rancher/k3s/token";
    # clusterInit = true; TODO for HA setup later
    
    extraFlags = toString [
      # handle in appropriate config file
    ];
  };

  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
  ];

  # Open ports for external access
  # 80/443: HTTP/HTTPS ingress traffic
  # 6443: Kubernetes API (for multi-node later)
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  # TODO: Add these for multi-node: 6443 2379 2380 10250
  networking.firewall.trustedInterfaces = [ "cni0" ];
  
  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  # Copy all needed config files
  environment.etc."rancher/k3s/config.yaml".source = ../../etc/rancher/k3s/config.yaml;
  environment.etc."dendrite/values.yaml".source = ../../etc/dendrite/values.yaml;
  environment.etc."dendrite/ingress.yaml".source = ../../etc/dendrite/ingress.yaml;

  # Deploy Dendrite after k3s is ready
  systemd.services.dendrite-deploy = {
    description = "Deploy Dendrite to Kubernetes";
    after = [ "k3s.service" ];
    wants = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = "KUBECONFIG=/etc/rancher/k3s/k3s.yaml";
    };
    
    script = ''
      # Wait for k3s to be ready
      until ${pkgs.kubectl}/bin/kubectl get nodes; do
        echo "Waiting for k3s..."
        sleep 5
      done
      
      # Add Dendrite Helm repo
      ${pkgs.kubernetes-helm}/bin/helm repo add dendrite https://matrix-org.github.io/dendrite/ || true
      ${pkgs.kubernetes-helm}/bin/helm repo update
      
      # Install or upgrade Dendrite
      ${pkgs.kubernetes-helm}/bin/helm upgrade --install dendrite dendrite/dendrite \
        -f /etc/dendrite/values.yaml \
        --create-namespace \
        --namespace matrix

      until ${pkgs.kubectl}/bin/kubectl get svc -n matrix dendrite; do
        echo "Waiting for Dendrite service..."
        sleep 5
      done

      until ${pkgs.kubectl}/bin/kubectl get endpoints -n matrix dendrite -o jsonpath='{.subsets[0].addresses[0].ip}' >/dev/null 2>&1; do
        echo "Waiting for Dendrite endpoints..."
        sleep 5
      done

      ${pkgs.kubectl}/bin/kubectl apply -f /etc/dendrite/ingress.yaml
      
      # Wait for Dendrite to be ready
      sleep 10
    '';
  };

}