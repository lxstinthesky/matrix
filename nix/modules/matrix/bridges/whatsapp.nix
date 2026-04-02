{ config, lib, ... }:
let
	fqdn = "${config.networking.hostName}.${config.networking.domain}";
	domainRegex = lib.replaceStrings [ "." ] [ "\\." ] config.networking.domain;
in
{
	sops.secrets = {
		"whatsapp/encryption-pickle-key" = {
			sopsFile = ../../../../secrets/whatsapp.yaml;
			restartUnits = [ "mautrix-whatsapp.service" ];
		};
		"whatsapp/public-media-signing-key" = {
			sopsFile = ../../../../secrets/whatsapp.yaml;
			restartUnits = [ "mautrix-whatsapp.service" ];
		};
		"whatsapp/direct-media-server-key" = {
			sopsFile = ../../../../secrets/whatsapp.yaml;
			restartUnits = [ "mautrix-whatsapp.service" ];
		};
		"whatsapp/double-puppet-as-token" = {
			sopsFile = ../../../../secrets/whatsapp.yaml;
			restartUnits = [ "mautrix-whatsapp.service" "${config.services.matrix-synapse.serviceUnit}" ];
		};
		"whatsapp/double-puppet-hs-token" = {
			sopsFile = ../../../../secrets/whatsapp.yaml;
			restartUnits = [ "${config.services.matrix-synapse.serviceUnit}" ];
		};
	};

	sops.templates."mautrix-whatsapp-env" = {
		owner = "mautrix-whatsapp";
		group = "mautrix-whatsapp";
		mode = "0400";
		content = ''
			MAUTRIX_WHATSAPP_ENCRYPTION_PICKLE_KEY=${config.sops.placeholder."whatsapp/encryption-pickle-key"}
			MAUTRIX_WHATSAPP_PUBLIC_MEDIA_SIGNING_KEY=${config.sops.placeholder."whatsapp/public-media-signing-key"}
			MAUTRIX_WHATSAPP_DIRECT_MEDIA_SERVER_KEY=${config.sops.placeholder."whatsapp/direct-media-server-key"}
			MAUTRIX_WHATSAPP_BRIDGE_LOGIN_SHARED_SECRET=as_token:${config.sops.placeholder."whatsapp/double-puppet-as-token"}
		'';
	};

	sops.templates."matrix-whatsapp-doublepuppet.yaml" = {
		owner = "matrix-synapse";
		group = "matrix-synapse";
		mode = "0440";
		content = lib.concatStringsSep "\n" [
			"id: doublepuppet"
			"url:"
			"as_token: ${config.sops.placeholder."whatsapp/double-puppet-as-token"}"
			"hs_token: ${config.sops.placeholder."whatsapp/double-puppet-hs-token"}"
			"sender_localpart: doublepuppet"
			"rate_limited: false"
			"namespaces:"
			"  users:"
			"    - regex: '@.*:${domainRegex}'"
			"      exclusive: false"
			""
		];
	};

	services.matrix-synapse.settings.app_service_config_files = [
		config.sops.templates."matrix-whatsapp-doublepuppet.yaml".path
	];

	services.mautrix-whatsapp = {
		enable = true;
		environmentFile = config.sops.templates."mautrix-whatsapp-env".path;
		serviceDependencies = [
			"postgresql.service"
			config.services.matrix-synapse.serviceUnit
		];
		settings = {
			homeserver = {
				address = "http://127.0.0.1:8008";
				domain = config.networking.domain;
			};

			appservice = {
				hostname = "127.0.0.1";
				id = "whatsapp";
				bot = {
					username = "whatsappbot";
					displayname = "WhatsApp Bridge Bot";
				};
			};

			database = {
				type = "postgres";
				uri = "postgresql:///mautrix-whatsapp?host=/run/postgresql";
			};

			bridge = {
				command_prefix = "!wa";
				private_chat_portal_meta = true;
				relay.enabled = true;
				sync_direct_chat_list = true;
				permissions = {
					"${config.networking.domain}" = "user";
				};
			};

			backfill.enabled = true;

			history_sync = {
				max_initial_conversations = 20;
				request_full_sync = false;
				media_requests = {
					auto_request_media = true;
					request_method = "immediate";
					max_async_handle = 2;
				};
			};

			double_puppet = {
				servers = {
					"${config.networking.domain}" = "https://${fqdn}";
				};
			};

			encryption = {
				allow = true;
				default = true;
				require = true;
				pickle_key = "$MAUTRIX_WHATSAPP_ENCRYPTION_PICKLE_KEY";
			};

			provisioning.shared_secret = "disable";
			public_media.signing_key = "$MAUTRIX_WHATSAPP_PUBLIC_MEDIA_SIGNING_KEY";
			direct_media.server_key = "$MAUTRIX_WHATSAPP_DIRECT_MEDIA_SERVER_KEY";
		};
	};
}
