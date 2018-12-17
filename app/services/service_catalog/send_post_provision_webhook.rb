module ServiceCatalog
  class SendPostProvisionWebhook < SendProvisionWebhook
    TITLE = "Post Provision Webhook".freeze

    def exists?
      portfolio_item.post_provision_webhook_id.present?
    end

    def webhook
      Webhook.find(portfolio_item.post_provision_webhook_id)
    end
  end
end
