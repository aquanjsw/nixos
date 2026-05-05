import json

from django.http import HttpRequest, JsonResponse
from django.conf import settings

SUBSCRIPTION_PATH = settings.SUBSCRIPTION_PATH

def config(request: HttpRequest):

    is_win = request.GET.get('win', '0') == '1'
    with_nft = request.GET.get('nft', '1') == '1'

    data = json.load(open(SUBSCRIPTION_PATH))

    for inbound in data['inbounds']:
        if 'auto_redirect' in inbound:
            inbound['auto_redirect'] = not is_win and with_nft

    return JsonResponse(data)