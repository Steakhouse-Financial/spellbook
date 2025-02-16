{{ config(
        alias ='pools',
        materialized = 'incremental',
        file_format = 'delta',
        incremental_strategy = 'merge',
        unique_key = ['blockchain', 'pool'],
        post_hook='{{ expose_spells(\'["ethereum", "arbitrum", "polygon"]\',
                                "sector",
                                "dex",
                                \'["hildobby"]\') }}'
        )
}}


{% set dex_pool_models = [
 ref('uniswap_pools')
 ,ref('spookyswap_fantom_pools')
] %}


SELECT *
FROM (
    {% for dex_pool_model in dex_pool_models %}
    SELECT
        blockchain
        , project
        , version
        , pool
        , fee
        , token0
        , token1
        , creation_block_time
        , creation_block_number
        , contract_address
    FROM {{ dex_pool_model }}
    {% if not loop.last %}
    {% if is_incremental() %}
    WHERE creation_block_time >= date_trunc("day", now() - interval '1 week')
    {% endif %}
    UNION ALL
    {% endif %}
    {% endfor %}
)
