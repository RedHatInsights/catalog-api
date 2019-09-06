FactoryBot.define do
  factory :image, :traits => [:has_tenant] do
    content { Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.svg"))) }
    extension { "SVG" }
  end
end
