% algorithm 4.1 from 

function [final_dictionary] = code_opt_alg_41(B, X, lambda, sigma)
    [M,D] = size(B); % M = codebook size, D = feature size
    [N,D1] = size(X); % N = num examples

    %objective_func = @(c) norm( X(i,:) - ( c * final_dictionary ) ) .^ 2 + ( lambda * norm( d .* c ) .^ 2 );
    
    % check dimensions match
    if(D ~= D1)
        error('Dim Mismatch', 'B should be M x D, X should be N x D');
    end
    
    final_dictionary = B;
    Aeq = ones(1, M); % optimization params
    Aeq_T = Aeq';
    %beq = 1;
    %A = [];
    %b = [];
    %options = optimoptions('fmincon');
    %options.MaxFunEvals = 10000;
    for i = 1:N
        fprintf(1, 'Optimizing codebook... %u out of %u\n', i, N);
        curr_X = X(i,:);
        %d = zeros(M,1);
        
        %locality constraint parameter
        %for j = 1:M
        %    d(j) = exp( norm(X(i,:) - B(j,:)) / sigma) .^ -1;
        %end
        %d = mat2gray(d); %normalize between 0 and 1
        
        % coding ( size(c) = [1, D] )
        %c(i,:) = %argmin(c) -> norm( X(i,:) - ( c * final_dictionary ) ) .^ 2 + ( lambda * norm( d .* c ) .^ 2 );
        %objective_func = @(c) norm( X(i,:) - ( c' * final_dictionary ) ) .^ 2 + ( lambda * norm( d .* c ) .^ 2 );
        
        % constrained optimization
        %c_init = final_dictionary(:,i);
        %c_i = fmincon(objective_func, c_init, A, b, Aeq, beq);
        
        %analytic solution to eq 3 (section 2.4.3):
        %dist = sp_dist2(curr_X, final_dictionary);
        dist_mat = exp(sp_dist2(curr_X, final_dictionary) ./ sigma);
        dist_mat = mat2gray(dist_mat); %normalize between 0 and 1
        B_C = final_dictionary - (Aeq_T * curr_X);
        Covar = B_C * B_C';
        c_til = (Covar + (lambda .* diag(dist_mat))) \ Aeq_T;
        c_i = c_til ./ (Aeq * c_til);
        
        % remove bias
        id = abs(c_i) > 0.01;
        B_i = final_dictionary(id,:);
        
        %solve LLC for ci
        Aeq2 = ones(size(B_i,1),1);
        B_1x = B_i - Aeq2 * curr_X;
        C = B_1x * B_1x';
        c_hat = C \ Aeq2;
        c_hat = c_hat / sum(c_hat);
        
        % update basis
        delta_Bi = -2 .* (c_hat * ( curr_X - c_hat' * B_i ) );
        %u = sqrt(1 / i);
        %B_i = B_i - ( (u .* delta_Bi) ./ norm(c_hat) );
        final_dictionary(id,:) = normr( B_i - ( (sqrt(1 / i) .* delta_Bi) ./ norm(c_hat) ) ); %project onto unit circle
    end
end