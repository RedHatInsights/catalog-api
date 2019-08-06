/*
 * Requires: https://github.com/RedHatInsights/insights-pipeline-lib
 */

@Library("github.com/RedHatInsights/insights-pipeline-lib") _


if (env.CHANGE_ID) {
    runSmokeTest (
        ocDeployerBuilderPath: "catalog/catalog-api,catalog/catalog-api-minion",
        ocDeployerComponentPath: "catalog/catalog-api,catalog/catalog-api-minion-approval,catalog/catalog-api-minion-order",
        ocDeployerServiceSets: "catalog,topological-inventory,sources,approval,platform-mq",
        iqePlugins: ["iqe-self-service-portal-plugin"],
        pytestMarker: "catalog_api_smoke",
        // local settings file
        configFileCredentialsId: "catalog-config",
    )
}
