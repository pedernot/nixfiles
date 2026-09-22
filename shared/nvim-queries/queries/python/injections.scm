; extends
((string
  (string_content) @injection.content)
  (#match? @injection.content "\\v\\cSELECT|INSERT|UPDATE|DELETE|WITH|CREATE|DROP|ALTER|TRUNCATE")
  (#set! injection.language "sql"))
