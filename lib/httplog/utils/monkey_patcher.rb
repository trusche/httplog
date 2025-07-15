# frozen_string_literal: true

# Designed to make all patches optional depending on user's configuration
module HttpLog
  module Utils
    module MonkeyPatcher
      class << self
        # @param configuration [HttpLog::Configuration]
        def apply(configuration)
          configuration.enabled_patches.each do |patch|
            registered_patches[patch].call
          end
        end

        # @param key [Symbol] provides flexibility in applying multiple patches to a single target
        # @param patch [Class]
        # @param target [Class]
        def register_patch(key, patch = nil, target = nil, &block)
          if patch && block
            raise ArgumentError.new('Please provide either a patch and its target OR a block, but not both')
          end

          if block
            registered_patches[key] = block
          else
            registered_patches[key] = proc do
              target.send(:prepend, patch) unless target.ancestors.include?(patch)
            end
          end
        end

        def registered_patches
          @registered_patches ||= {}
        end

        def validate!(patches)
          output = registered_patches.keys & patches

          if output.size != patches.size
            raise HttpLog::Configuration::PatchesError.new("Please check registered patches: #{registered_patches.keys}")
          end
        end
      end
    end
  end
end
