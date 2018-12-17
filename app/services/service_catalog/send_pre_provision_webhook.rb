module ServiceCatalog
  class SendPreProvisionWebhook < SendProvisionWebhook
    TITLE = "Pre Provision Webhook".freeze

    def exists?
      portfolio_item.pre_provision_webhook_id.present?
    end

    def webhook
      Webhook.find(portfolio_item.pre_provision_webhook_id)
    end
  end
end
