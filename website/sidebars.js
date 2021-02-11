module.exports = {
  docs: [
    "index",
    {
      type: "category",
      label: "Getting started",
      items: [
        "getting-started/installation",
        "getting-started/relay-environment",
        "getting-started/fetching-data",
        "getting-started/fragments",
        "getting-started/mutations",
      ],
    },
    {
      type: "category",
      label: "API reference",
      items: [
        {
          type: "category",
          label: "Relay.swift",
          items: [
            "api/graphql",
            "api/environment",
            "api/network",
            "api/store",
            "api/record-source-selector-proxy",
            "api/record-proxy",
            "api/connection-handler",
            "api/mock-environment",
          ],
        },
      ],
    },
  ],
};
