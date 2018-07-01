module Cani
  class Feature
    attr_reader :title, :status, :spec, :stats

    def initialize(attributes = {})
      @title  = attributes['title']
      @status = attributes['status']
      @spec   = attributes['spec']
      @stats  = attributes['stats'].each_with_object({}) do |(k, v), h|
        h[k] = v.to_a.last(Cani.config.versions).to_h
      end
    end

    def support_in(browser, version)
      case @stats[browser.to_s][version.to_s].to_s[0]
      when 'y' then :supported
      when 'a' then :partial
      when 'n' then :unsupported
      when 'p' then :polyfill
      when 'x' then :prefix
      when 'd' then :flag
      else :unknown
      end
    end

    def browser_info(browser, version)
      {
        support: support_in(browser, version),
        title:   title,
        status:  status,
        spec:    spec
      }
    end
  end
end
