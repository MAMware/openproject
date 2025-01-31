# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Peripherals
    module StorageInteraction
      module OneDrive
        class FilesInfoQuery
          include StorageErrorHelper

          using ServiceResultRefinements

          def self.call(storage:, user:, file_ids: [])
            new(storage).call(user:, file_ids:)
          end

          def initialize(storage)
            @storage = storage
            @uri = storage.uri
          end

          def call(user:, file_ids:)
            if file_ids.nil?
              return ServiceResult.failure(
                result: :error,
                errors: ::Storages::StorageError.new(code: :error, log_message: 'File IDs can not be nil')
              )
            end

            result = file_ids.map do |file_id|
              wrap_storage_file_error(file_id, FileInfoQuery.call(storage: @storage, user:, file_id:))
            end

            ServiceResult.success(result:)
          end

          private

          def wrap_storage_file_error(file_id, query_result)
            if query_result.success?
              query_result.result
            else
              storage_error = query_result.errors
              StorageFileInfo.new(
                id: file_id,
                status: storage_error.data.dig(:error, :code),
                status_code: Rack::Utils::SYMBOL_TO_STATUS_CODE[storage_error.code]
              )
            end
          end
        end
      end
    end
  end
end
