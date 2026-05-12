import json

from django.http import HttpRequest, JsonResponse
from django.conf import settings

SUBSCRIPTION_PATH = settings.SUBSCRIPTION_PATH

def config(request: HttpRequest):

    is_win = request.GET.get('win', '0') == '1'
    enable_strict_route = request.GET.get('strict_route', '1') == '1'
    with_nft = request.GET.get('nft', '1') == '1'
    use_fakeip = request.GET.get('fakeip', '1') == '1'
    mtu = request.GET.get('mtu', '0')
    loglevel = request.GET.get('loglevel', 'info')
    stack = request.GET.get('stack', '')

    data = json.load(open(SUBSCRIPTION_PATH))

    for inbound in data['inbounds']:
        if inbound['type'] == 'tun':
            inbound['auto_redirect'] = not is_win and with_nft
            inbound['strict_route'] = enable_strict_route
            try:
                val = int(mtu)
                if val < 1280 or val > 1500:
                    raise ValueError
                inbound['mtu'] = val
            except ValueError:
                pass
            if stack in ['mixed', 'system', 'gvisor']:
                inbound['stack'] = stack

    if not use_fakeip:
        for rule in data['dns']['rules']:
            if rule['server'] == 'fakeip':
                data['dns']['rules'].remove(rule)

    if loglevel in ['trace', 'debug', 'info', 'warn', 'error', 'fatal', 'panic']:
        data['log']['level'] = loglevel

    return JsonResponse(data)
