{ config, lib, pkgs, ... }:
let
	fqdn = "${config.networking.hostName}.${config.networking.domain}";
	domainRegex = lib.replaceStrings [ "." ] [ "\\." ] config.networking.domain;
	registrationFile = "/var/lib/matrix-hookshot/registration.yml";
	hookshotUser = "matrix-hookshot";
	hookshotGroup = "matrix-hookshot";
in
{
	services.matrix-synapse.settings.app_service_config_files = [ registrationFile ];

	services.matrix-hookshot = {
		enable = true;
		registrationFile = registrationFile;
		serviceDependencies = [ config.services.matrix-synapse.serviceUnit ];
		settings = {
			passFile = "/var/lib/matrix-hookshot/passkey.pem";

			bridge = {
				domain = config.networking.domain;
				url = "http://127.0.0.1:8008";
				mediaUrl = "https://${fqdn}";
				port = 9993;
				bindAddress = "127.0.0.1";
			};

			listeners = [
				{
					port = 9003;
					bindAddress = "127.0.0.1";
					resources = [ "webhooks" ];
				}
				{
					port = 9004;
					bindAddress = "127.0.0.1";
					resources = [ "metrics" ];
				}
			];

			permissions = [
				{
					actor = config.networking.domain;
					services = [
						{
							service = "*";
							level = "admin";
						}
					];
				}
			];

			generic = {
				enabled = true;
				outbound = false;
				urlPrefix = "https://${fqdn}/hookshot/webhook/";
				userIdPrefix = "_webhooks_";
				allowJsTransformationFunctions = false;
				waitForComplete = false;
				enableHttpGet = false;
				sendExpiryNotice = false;
				requireExpiryTime = false;
				includeHookBody = true;
			};

			feeds = {
				enabled = true;
				pollIntervalSeconds = 600;
				pollTimeoutSeconds = 30;
				pollConcurrency = 4;
			};

			bot.displayname = "Hookshot Bot";
			serviceBots = [
				{
					localpart = "feeds";
					displayname = "Feeds";
					prefix = "!feeds";
					service = "feeds";
				}
			];

			metrics.enabled = true;
		};
	};

	systemd.services.matrix-hookshot-registration = {
		description = "Generate matrix-hookshot registration file";
		wantedBy = [ config.services.matrix-synapse.serviceUnit "matrix-hookshot.service" ];
		before = [ config.services.matrix-synapse.serviceUnit "matrix-hookshot.service" ];
		serviceConfig = {
			Type = "oneshot";
			User = "root";
			Group = "root";
		};
		script = ''
			install -d -m 0750 -o ${hookshotUser} -g ${hookshotGroup} /var/lib/matrix-hookshot

			if [ ! -f ${registrationFile} ]; then
				as_token="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
				hs_token="$(${pkgs.openssl}/bin/openssl rand -hex 32)"

				cat > ${registrationFile} <<'EOF'
		id: hookshot
		url: http://127.0.0.1:9993
		as_token: __AS_TOKEN__
		hs_token: __HS_TOKEN__
		sender_localpart: hookshot
		rate_limited: false
		namespaces:
		  rooms: []
		  aliases: []
		  users:
		    - regex: '@hookshot:${domainRegex}'
		      exclusive: true
		    - regex: '@feeds:${domainRegex}'
		      exclusive: true
		    - regex: '@_webhooks_.*:${domainRegex}'
		      exclusive: true
		EOF

				${pkgs.gnused}/bin/sed -i \
					-e "s|__AS_TOKEN__|$as_token|" \
					-e "s|__HS_TOKEN__|$hs_token|" \
					${registrationFile}
			fi

			chown ${hookshotUser}:matrix-synapse ${registrationFile}
			chmod 0440 ${registrationFile}
		'';
	};

	services.nginx.virtualHosts."${fqdn}" = {
		locations."= /hookshot".extraConfig = ''
			return 302 /hookshot/;
		'';
		locations."^~ /hookshot/" = {
			priority = 400;
			proxyPass = "http://127.0.0.1:9003";
		};
	};
}
