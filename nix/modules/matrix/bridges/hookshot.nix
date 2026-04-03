{ config, lib, ... }:
let
	fqdn = "${config.networking.hostName}.${config.networking.domain}";
	domainRegex = lib.replaceStrings [ "." ] [ "\\." ] config.networking.domain;
in
{
	sops.secrets = {
		"hookshot/as-token" = {
			sopsFile = ../../../../secrets/hookshot.yaml;
			restartUnits = [ "matrix-hookshot.service" "${config.services.matrix-synapse.serviceUnit}" ];
		};
		"hookshot/hs-token" = {
			sopsFile = ../../../../secrets/hookshot.yaml;
			restartUnits = [ "${config.services.matrix-synapse.serviceUnit}" ];
		};
		"hookshot/passkey" = {
			owner = "matrix-hookshot";
			group = "matrix-hookshot";
			mode = "0400";
			sopsFile = ../../../../secrets/hookshot.yaml;
			restartUnits = [ "matrix-hookshot.service" ];
		};
	};

	sops.templates."matrix-hookshot-registration.yaml" = {
		owner = "matrix-synapse";
		group = "matrix-synapse";
		mode = "0440";
		content = lib.concatStringsSep "\n" [
			"id: hookshot"
			"url: http://127.0.0.1:9993"
			"as_token: ${config.sops.placeholder."hookshot/as-token"}"
			"hs_token: ${config.sops.placeholder."hookshot/hs-token"}"
			"sender_localpart: hookshot"
			"rate_limited: false"
			"namespaces:"
			"  rooms: []"
			"  aliases: []"
			"  users:"
			"    - regex: '@hookshot:${domainRegex}'"
			"      exclusive: true"
			"    - regex: '@feeds:${domainRegex}'"
			"      exclusive: true"
			"    - regex: '@_webhooks_.*:${domainRegex}'"
			"      exclusive: true"
			""
		];
	};

	services.matrix-synapse.settings.app_service_config_files = [
		config.sops.templates."matrix-hookshot-registration.yaml".path
	];

	services.matrix-hookshot = {
		enable = true;
		registrationFile = config.sops.templates."matrix-hookshot-registration.yaml".path;
		serviceDependencies = [ config.services.matrix-synapse.serviceUnit ];
		settings = {
			passFile = config.sops.secrets."hookshot/passkey".path;

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
