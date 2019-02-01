module Api
  module V0x1
    class AdminsController < Api::V0x0::AdminsController
      include Api::V0x1::Mixins::IndexMixin
    end

    class UsersController < Api::V0x0::UsersController
      include Api::V0x1::Mixins::IndexMixin
    end

    class BaseController < Api::V0x0::BaseController
      include Api::V0x1::Mixins::IndexMixin
    end
  end
end
