# vim:set ft= ts=4 sw=4 et fdm=marker:

use Test::Nginx::Socket::Lua::Stream;
use FindBin qw($Bin);
my $root_path = $Bin;
our $MOTAN_P_ROOT=$root_path . "/../lib/";
our $MOTAN_CPATH=$root_path . "/../lib/motan/libs/";
our $MOTAN_DEMO_PATH=$root_path . "/motan-demo/";

our $http_config=<<"_EOC_";
    lua_package_path '$MOTAN_DEMO_PATH/?.lua;$MOTAN_DEMO_PATH/?/init.lua;$MOTAN_P_ROOT/?.lua;$MOTAN_P_ROOT/?/init.lua;./?.lua;/?.lua;/?/init.lua;;';
    lua_package_cpath '$MOTAN_CPATH/?.so;;';
    init_by_lua_block {
        motan = require 'motan'
        motan.init()
    }
_EOC_

$ENV{TEST_NGINX_SERVER_PORT} = 1990;
$ENV{MOTAN_ENV} = "development";
log_level('warn');
#worker_connections(1014);
#master_on();
#workers(2);

repeat_each(2);

plan tests => repeat_each() * (blocks() * 2);
# use Test::Nginx::Socket::Lua::Stream 'no_plan'

# no_diff();
#no_long_string();
run_tests();

# DTYPE_NULL = 0
# DTYPE_STRING = 1
# DTYPE_STRING_MAP = 2
# DTYPE_BYTE_ARRAY = 3
# DTYPE_STRING_ARRAY = 4
# DTYPE_BOOL = 5
# DTYPE_BYTE = 6
# DTYPE_INT16 = 7
# DTYPE_INT32 = 8
# DTYPE_INT64 = 9
# DTYPE_FLOAT32 = 10
# DTYPE_FLOAT64 = 11

# DTYPE_MAP = 20
# DTYPE_ARRAY = 21

__DATA__

=== TEST 1: motan openresty simple serialize - Null
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = nil
            local bytes = serialize_lib.serialize(t_data)

            local res = serialize_lib.deserialize(bytes)
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
nil

=== TEST 2: motan openresty simple serialize - String
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = '阿波罗a'
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
阿波罗a

=== TEST 3: motan openresty simple serialize - StringMap
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 
            {
                A="motan-openresty",
                aa="motan-openresty",
                aal="motan-openresty",
                aalii="motan-openresty",
                aam="motan-openresty",
                Aani="motan-openresty",
                aardvark="motan-openresty",
                aardwolf="motan-openresty",
                Aaron="motan-openresty",
                Aaronic="motan-openresty",
                Aaronical="motan-openresty",
                Aaronite="motan-openresty",
                Aaronitic="motan-openresty",
                Aaru="motan-openresty",
                Ab="motan-openresty",
                aba="motan-openresty",
                Ababdeh="motan-openresty",
                Ababua="motan-openresty",
                abac="motan-openresty",
                abaca="motan-openresty",
                abacate="motan-openresty",
                abacay="motan-openresty",
                abacinate="motan-openresty",
                abacination="motan-openresty",
                abaciscus="motan-openresty",
                abacist="motan-openresty",
                aback="motan-openresty",
                abactinal="motan-openresty",
                abactinally="motan-openresty",
                abaction="motan-openresty",
                abactor="motan-openresty",
                abaculus="motan-openresty",
                abacus="motan-openresty",
                Abadite="motan-openresty",
                abaff="motan-openresty",
                abaft="motan-openresty",
                abaisance="motan-openresty",
                abaiser="motan-openresty",
                abaissed="motan-openresty",
                abalienate="motan-openresty",
                abalienation="motan-openresty",
                abalone="motan-openresty",
                Abama="motan-openresty",
                abampere="motan-openresty",
                abandon="motan-openresty",
                abandonable="motan-openresty",
                abandoned="motan-openresty",
                abandonedly="motan-openresty",
                abandonee="motan-openresty",
                abandoner="motan-openresty",
                abandonment="motan-openresty",
                Abanic="motan-openresty",
                Abantes="motan-openresty",
                abaptiston="motan-openresty",
                Abarambo="motan-openresty",
                Abaris="motan-openresty",
                abarthrosis="motan-openresty",
                abarticular="motan-openresty",
                abarticulation="motan-openresty",
                abas="motan-openresty",
                abase="motan-openresty",
                abased="motan-openresty",
                abasedly="motan-openresty",
                abasedness="motan-openresty",
                abasement="motan-openresty",
                abaser="motan-openresty",
                Abasgi="motan-openresty",
                abash="motan-openresty",
                abashed="motan-openresty",
                abashedly="motan-openresty",
                abashedness="motan-openresty",
                abashless="motan-openresty",
                abashlessly="motan-openresty",
                abashment="motan-openresty",
                abasia="motan-openresty",
                abasic="motan-openresty",
                abask="motan-openresty",
                Abassin="motan-openresty",
                abastardize="motan-openresty",
                abatable="motan-openresty",
                abate="motan-openresty",
                abatement="motan-openresty",
                abater="motan-openresty",
                abatis="motan-openresty",
                abatised="motan-openresty",
                abaton="motan-openresty",
                abator="motan-openresty",
                abattoir="motan-openresty",
                Abatua="motan-openresty",
                abature="motan-openresty",
                abave="motan-openresty",
                abaxial="motan-openresty",
                abaxile="motan-openresty",
                abaze="motan-openresty",
                abb="motan-openresty",
                Abba="motan-openresty",
                abbacomes="motan-openresty",
                abbacy="motan-openresty",
                Abbadide="motan-openresty",
                abbas="motan-openresty",
                abbasi="motan-openresty",
                abbassi="motan-openresty",
                Abbasside="motan-openresty",
                abbatial="motan-openresty",
                abbatical="motan-openresty",
                abbess="motan-openresty",
                abbey="motan-openresty",
                abbeystede="motan-openresty",
                Abbie="motan-openresty",
                abbot="motan-openresty",
                abbotcy="motan-openresty",
                abbotnullius="motan-openresty",
                abbotship="motan-openresty",
                abbreviate="motan-openresty",
                abbreviately="motan-openresty",
                abbreviation="motan-openresty",
                abbreviator="motan-openresty",
                abbreviatory="motan-openresty",
                abbreviature="motan-openresty",
                Abby="motan-openresty",
                abcoulomb="motan-openresty",
                abdal="motan-openresty",
                abdat="motan-openresty",
                Abderian="motan-openresty",
                Abderite="motan-openresty",
                abdest="motan-openresty",
                abdicable="motan-openresty",
                abdicant="motan-openresty",
                abdicate="motan-openresty",
                abdication="motan-openresty",
                abdicative="motan-openresty",
                abdicator="motan-openresty",
                Abdiel="motan-openresty",
                abditive="motan-openresty",
                abditory="motan-openresty",
                abdomen="motan-openresty",
                abdominal="motan-openresty",
                Abdominales="motan-openresty",
                abdominalian="motan-openresty",
                abdominally="motan-openresty",
                abdominoanterior="motan-openresty",
                abdominocardiac="motan-openresty",
                abdominocentesis="motan-openresty",
                abdominocystic="motan-openresty",
                abdominogenital="motan-openresty",
                abdominohysterectomy="motan-openresty",
                abdominohysterotomy="motan-openresty",
                abdominoposterior="motan-openresty",
                abdominoscope="motan-openresty",
                abdominoscopy="motan-openresty",
                abdominothoracic="motan-openresty",
                abdominous="motan-openresty",
                abdominovaginal="motan-openresty",
                abdominovesical="motan-openresty",
                abduce="motan-openresty",
                abducens="motan-openresty",
                abducent="motan-openresty",
                abduct="motan-openresty",
                abduction="motan-openresty",
                abductor="motan-openresty",
                Abe="motan-openresty",
                abeam="motan-openresty",
                abear="motan-openresty",
                abearance="motan-openresty",
                abecedarian="motan-openresty",
                abecedarium="motan-openresty",
                abecedary="motan-openresty",
                abed="motan-openresty",
                abeigh="motan-openresty",
                Abel="motan-openresty",
                abele="motan-openresty",
                Abelia="motan-openresty",
                Abelian="motan-openresty",
                Abelicea="motan-openresty",
                abelite="motan-openresty",
                Abelite="motan-openresty",
                Abelmoschus="motan-openresty",
                abelmosk="motan-openresty",
                Abelonian="motan-openresty",
                abeltree="motan-openresty",
                Abencerrages="motan-openresty",
                abenteric="motan-openresty",
                abepithymia="motan-openresty",
                Aberdeen="motan-openresty",
                aberdevine="motan-openresty",
                Aberdonian="motan-openresty",
                Aberia="motan-openresty",
                aberrance="motan-openresty",
                aberrancy="motan-openresty",
                aberrant="motan-openresty",
                aberrate="motan-openresty",
                aberration="motan-openresty",
                aberrational="motan-openresty",
                aberrator="motan-openresty",
                aberrometer="motan-openresty",
                aberroscope="motan-openresty",
                aberuncator="motan-openresty",
                abet="motan-openresty",
                abetment="motan-openresty",
                abettal="motan-openresty",
                abettor="motan-openresty",
                abevacuation="motan-openresty",
                abey="motan-openresty",
                abeyance="motan-openresty",
                abeyancy="motan-openresty",
                abeyant="motan-openresty",
                abfarad="motan-openresty",
                abhenry="motan-openresty",
                abhiseka="motan-openresty",
                abhominable="motan-openresty",
                abhor="motan-openresty",
                abhorrence="motan-openresty",
                abhorrency="motan-openresty",
                abhorrent="motan-openresty",
                abhorrently="motan-openresty",
                abhorrer="motan-openresty",
                abhorrible="motan-openresty",
                abhorring="motan-openresty",
                Abhorson="motan-openresty",
                abidal="motan-openresty",
                abidance="motan-openresty",
                abide="motan-openresty",
                abider="motan-openresty",
                abidi="motan-openresty",
                abiding="motan-openresty",
                abidingly="motan-openresty",
                abidingness="motan-openresty",
                Abie="motan-openresty",
                Abies="motan-openresty",
                abietate="motan-openresty",
                abietene="motan-openresty",
                abietic="motan-openresty",
                abietin="motan-openresty",
                Abietineae="motan-openresty",
                abietineous="motan-openresty",
                abietinic="motan-openresty",
                Abiezer="motan-openresty",
                abigail="motan-openresty",
                Abigail="motan-openresty",
                abigailship="motan-openresty",
                abigeat="motan-openresty",
                abigeus="motan-openresty",
                abilao="motan-openresty",
                ability="motan-openresty",
                abilla="motan-openresty",
                abilo="motan-openresty",
                abintestate="motan-openresty",
                abiogenesis="motan-openresty",
                abiogenesist="motan-openresty",
                abiogenetic="motan-openresty",
                abiogenetical="motan-openresty",
                abiogenetically="motan-openresty",
                abiogenist="motan-openresty",
                abiogenous="motan-openresty",
                abiogeny="motan-openresty",
                abiological="motan-openresty",
                abiologically="motan-openresty",
                abiology="motan-openresty",
                abiosis="motan-openresty",
                abiotic="motan-openresty",
                abiotrophic="motan-openresty",
                abiotrophy="motan-openresty",
                Abipon="motan-openresty",
                abir="motan-openresty",
                abirritant="motan-openresty",
                abirritate="motan-openresty",
                abirritation="motan-openresty",
                abirritative="motan-openresty",
                abiston="motan-openresty",
                Abitibi="motan-openresty",
                abiuret="motan-openresty",
                abject="motan-openresty",
                abjectedness="motan-openresty",
                abjection="motan-openresty",
                abjective="motan-openresty",
                abjectly="motan-openresty",
                abjectness="motan-openresty",
                abjoint="motan-openresty",
                abjudge="motan-openresty",
                abjudicate="motan-openresty",
                abjudication="motan-openresty",
                abjunction="motan-openresty",
                abjunctive="motan-openresty",
                abjuration="motan-openresty",
                abjuratory="motan-openresty",
                abjure="motan-openresty",
                abjurement="motan-openresty",
                abjurer="motan-openresty",
                abkar="motan-openresty",
                abkari="motan-openresty",
                Abkhas="motan-openresty",
                Abkhasian="motan-openresty",
                ablach="motan-openresty",
                ablactate="motan-openresty",
                ablactation="motan-openresty",
                ablare="motan-openresty",
                ablastemic="motan-openresty",
                ablastous="motan-openresty",
                ablate="motan-openresty",
                ablation="motan-openresty",
                ablatitious="motan-openresty",
                ablatival="motan-openresty",
                ablative="motan-openresty",
                ablator="motan-openresty",
                ablaut="motan-openresty",
                ablaze="motan-openresty",
                able="motan-openresty",
                ableeze="motan-openresty",
                ablegate="motan-openresty",
                ableness="motan-openresty",
                ablepharia="motan-openresty",
                ablepharon="motan-openresty",
                ablepharous="motan-openresty",
                Ablepharus="motan-openresty",
                ablepsia="motan-openresty",
                ableptical="motan-openresty",
                ableptically="motan-openresty",
                abler="motan-openresty",
                ablest="motan-openresty",
                ablewhackets="motan-openresty",
                ablins="motan-openresty",
                abloom="motan-openresty",
                ablow="motan-openresty",
                ablude="motan-openresty",
                abluent="motan-openresty",
                ablush="motan-openresty",
                ablution="motan-openresty",
                ablutionary="motan-openresty",
                abluvion="motan-openresty",
                ably="motan-openresty",
                abmho="motan-openresty",
                Abnaki="motan-openresty",
                abnegate="motan-openresty",
                abnegation="motan-openresty",
                abnegative="motan-openresty",
                abnegator="motan-openresty",
                Abner="motan-openresty",
                abnerval="motan-openresty",
                abnet="motan-openresty",
                abneural="motan-openresty",
                abnormal="motan-openresty",
                abnormalism="motan-openresty",
                abnormalist="motan-openresty",
                abnormality="motan-openresty",
                abnormalize="motan-openresty",
                abnormally="motan-openresty",
                abnormalness="motan-openresty",
                abnormity="motan-openresty",
                abnormous="motan-openresty",
                abnumerable="motan-openresty",
                Abo="motan-openresty",
                aboard="motan-openresty",
                Abobra="motan-openresty",
                abode="motan-openresty",
                abodement="motan-openresty",
                abody="motan-openresty",
                abohm="motan-openresty",
                aboil="motan-openresty",
                abolish="motan-openresty",
                abolisher="motan-openresty",
                abolishment="motan-openresty",
                abolition="motan-openresty",
                abolitionary="motan-openresty",
                abolitionism="motan-openresty",
                abolitionist="motan-openresty",
                abolitionize="motan-openresty",
                abolla="motan-openresty",
                aboma="motan-openresty",
                abomasum="motan-openresty",
                abomasus="motan-openresty",
                abominable="motan-openresty",
                abominableness="motan-openresty",
                abominably="motan-openresty",
                abominate="motan-openresty",
                abomination="motan-openresty",
                abominator="motan-openresty",
                abomine="motan-openresty",
                Abongo="motan-openresty",
                aboon="motan-openresty",
                aborad="motan-openresty",
                aboral="motan-openresty",
                aborally="motan-openresty",
                abord="motan-openresty",
                aboriginal="motan-openresty",
                aboriginality="motan-openresty",
                aboriginally="motan-openresty",
                aboriginary="motan-openresty",
                aborigine="motan-openresty",
                abort="motan-openresty",
                aborted="motan-openresty",
                aborticide="motan-openresty",
                abortient="motan-openresty",
                abortifacient="motan-openresty",
                abortin="motan-openresty",
                abortion="motan-openresty",
                abortional="motan-openresty",
                abortionist="motan-openresty",
                abortive="motan-openresty",
                abortively="motan-openresty",
                abortiveness="motan-openresty",
                abortus="motan-openresty",
                abouchement="motan-openresty",
                abound="motan-openresty",
                abounder="motan-openresty",
                abounding="motan-openresty",
                aboundingly="motan-openresty",
                about="motan-openresty",
                abouts="motan-openresty",
                above="motan-openresty",
                aboveboard="motan-openresty",
                abovedeck="motan-openresty",
                aboveground="motan-openresty",
                aboveproof="motan-openresty",
                abovestairs="motan-openresty",
                abox="motan-openresty",
                abracadabra="motan-openresty",
                abrachia="motan-openresty",
                abradant="motan-openresty",
                abrade="motan-openresty",
                abrader="motan-openresty",
                Abraham="motan-openresty",
                Abrahamic="motan-openresty",
                Abrahamidae="motan-openresty",
                Abrahamite="motan-openresty",
                Abrahamitic="motan-openresty",
                abraid="motan-openresty",
                Abram="motan-openresty",
                Abramis="motan-openresty",
                abranchial="motan-openresty",
                abranchialism="motan-openresty",
                abranchian="motan-openresty",
                Abranchiata="motan-openresty",
                abranchiate="weibo-com-motan-openresty",
                abranchious="motan-openresty",
                abrasax="motan-openresty",
                abrase="motan-openresty",
                abrash="motan-openresty",
                abrasiometer="9999999",
                abrasion="motan-openresty",
                abrasive="motan-openresty",
                abrastol="motan-openresty",
                abraum="motan-openresty",
                abraxas="motan-openresty",
                abreact="motan-openresty",
                abreaction="motan-openresty",
                abreast="motan-openresty",
                abrenounce="motan-openresty",
                abret="motan-openresty",
                abrico="motan-openresty",
                abridge="motan-openresty",
                abridgeable="motan-openresty",
                abridged="motan-openresty",
                abridgedly="motan-openresty",
                abridger="motan-openresty",
                abridgment="motan-openresty",
                abrim="motan-openresty",
                abrin="motan-openresty",
                abristle="motan-openresty",
                abroach="motan-openresty",
                abroad="motan-openresty",
                Abrocoma="motan-openresty",
                abrocome="motan-openresty",
                abrogable="motan-openresty",
                abrogate="motan-openresty",
                abrogation="motan-openresty",
                abrogative="motan-openresty",
                abrogator="motan-openresty",
                Abroma="motan-openresty",
                Abronia="motan-openresty",
                abrook="motan-openresty",
                abrotanum="motan-openresty",
                abrotine="motan-openresty",
                abrupt="motan-openresty",
                abruptedly="motan-openresty",
                abruption="motan-openresty",
                abruptly="motan-openresty",
                abruptness="motan-openresty",
                Abrus="motan-openresty",
                Absalom="motan-openresty",
                absampere="motan-openresty",
                Absaroka="motan-openresty",
                absarokite="motan-openresty",
                abscess="motan-openresty",
                abscessed="motan-openresty",
                abscession="motan-openresty",
                abscessroot="motan-openresty",
                abscind="motan-openresty",
                abscise="motan-openresty",
                abscision="motan-openresty",
                absciss="motan-openresty",
                abscissa="motan-openresty",
                abscissae="motan-openresty",
                abscisse="motan-openresty",
                abscission="motan-openresty",
                absconce="motan-openresty",
                abscond="motan-openresty",
                absconded="motan-openresty",
                abscondedly="motan-openresty",
                abscondence="motan-openresty"
            }
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(res['abranchiate'] .. res['abrasiometer'])
        }
    }
--- request
GET /t
--- response_body
weibo-com-motan-openresty9999999
--- ONLY

=== TEST 4: motan openresty simple serialize - ByteArray
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = {1, 2, 3, 123, 255}
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(sprint_r(res))
        }
    }
--- request
GET /t
--- response_body
{
  1,
  2,
  3,
  123,
  255
}

=== TEST 5: motan openresty simple serialize - StringArray
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = {'阿波罗a', '阿波罗b'}
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(sprint_r(res))
        }
    }
--- request
GET /t
--- response_body
{
  "阿波罗a",
  "阿波罗b"
}

=== TEST 6: motan openresty simple serialize - Bool
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = true
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
true

=== TEST 7: motan openresty simple serialize - Byte
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 1
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
1

=== TEST 8: motan openresty simple serialize - Int16
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 65535
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
65535

=== TEST 9: motan openresty simple serialize - Int32
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 429496729
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
429496729

=== TEST 10: motan openresty simple serialize - Int64
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            -- local t_data = 72057594037927935
            local t_data = 429496729
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
429496729

=== TEST 11: motan openresty simple serialize - Float32
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 429496729.333333
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
429496729

=== TEST 12: motan openresty simple serialize - Float64
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local t_data = 429496729.333333
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(res)
        }
    }
--- request
GET /t
--- response_body
429496729

=== TEST 13: motan openresty simple serialize - Map
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local str_arr = {one='阿波罗a'}
            local t_data = {name=str_arr}
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(sprint_r(res))
        }
    }
--- request
GET /t
--- response_body
{
  name = {
    one = "阿波罗a"
  }
}

=== TEST 14: motan openresty simple serialize - Array
--- http_config eval: $::http_config
--- config
    location /t {
        content_by_lua_block {
            local singletons = require 'motan.singletons'
            local serialize_lib = singletons.motan_ext:get_serialization('simple')
            local str_arr_a = {one='阿波罗a'}
            local str_arr_b = {two='阿波罗b'}
            local t_data = {str_arr_a, str_arr_b}
            local bytes = serialize_lib.serialize(t_data)
            
            local res = serialize_lib.deserialize(bytes)
            ngx.say(sprint_r(res))
        }
    }
--- request
GET /t
--- response_body
{
  {
    one = "阿波罗a"
  },
  {
    two = "阿波罗b"
  }
}
